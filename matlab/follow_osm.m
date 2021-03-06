function [X, D, T] = follow_osm(lon, lat, delta_t, tag, fitness, varargin)
    % FOLLOW_OSM_FREE Berechnet Route entlang Straßen und Wegen, wenn Sonne
    % hinterhergelaufen wird
    %   Aufruf: [X, D, T] = follow_osm_free(lon, lat, delta_t, tag, fitness, varargin) mit
    %   lon         skalarer Längengrad,
    %   lat         skalarer Breitengrad,
    %   delta_t     Zeitschrittlänge in Minuten
    %   tag         Tag als Tag des Jahres, d.h. 1 <= tag <= 365
    %   fitness     ein Struct mit den Feldern
    %                 walkpause   2xn Array mit Lauf- und Pausenzeiten
    %                 f           Cell-Array von Funktionen, die die Laufgschwindigkeit
    %                             in Abhängigkeit von der Zeit beschreibt
    %   varargin    wird 'NoElevation' mitübergeben, werden keine Höhendaten verwendet
    %   X           2xm Array der Koordinaten jedes Schrittes der Route
    %   D           in jedem Schritt zurückgelegte Distanz (kumulativ)
    %   T           Zeitpunkt jedes Schrittes in unserem Zeitformat (Minuten seit 1.1.
    %               00:00)
    %
    %   Ausgabe auf der Kommandozeile während Berechnung:
    %   [n][Q t1 s][P t2 s][A t3 s]
    %   n: n-te benutzte Karte,
    %   t1: Zeit für Anfrage an OSM-Server (Q -> Query)
    %   t2: Zeit für Parsen der Daten (P -> Parse)
    %   t3: Zeit für berechnen der Adjazenzmatrix (A -> Adjacency matrix)
    %
    %   wurde die Karte lokal gefunden wird der Block [Q ..][P ..] durch [L] ersetzt
    
    % muss Spaltenvektor sein!
    coord = [lon; lat];
    coord_prev = coord;
    earth_radius = 6371000;
    
    % Werte initialisieren
    p = lonlat2vec(lon, lat, earth_radius);
    [t, visible, t_unter] = sonnenaufgang(p, tag);
    % maximal einen Tag lang
    t_end = t + 1440;
    day_dur = t_unter-t;
    
    % initialisiere Arrays, werden dynamisch vergrößert:
    % Folge der besuchten Koordinaten, betrachtete Zeitpunkte, universelle ID der
    % besuchten Knoten, zurückgelegte Distanz, und Höhe zum entsprechenden Zeitpunkt
    X = coord;
    T = t;
    N = zeros(1, 0); N(1,1) = 0;
    D = zeros(1, 0); D(1,1) = 0;
    E = zeros(1, 0); E(1,1) = 0;
    
    if size(fitness.walkpause, 1) ~= 2
        fprintf('Laufpause-Array falsch dimensioniert.\n');
        return;
    end
    
    consider_elevation = ~any(strcmpi(varargin, 'NoElevation'));
    
    endlastbreak = t;
    fnpperiod = size(fitness.walkpause, 2);
    fnfperiod = size(fitness.f, 2);
    
    pauseidx = 1;
   
    % Abstand zu Grenzen in Längen-/Breitengraden
    br_lat = 0.006;
    br_lon = 0.009;
    
    % Initialisiere Bounding Box als Punkt
    bounds = [lat lon lat lon];
    
    step = 1;
    maps_used = 0;
    
    % Format für Karten-Dateinamen
    map_filename_spec = 'map-%f_%f_%f_%f.mat';
    map_dir_name = fullfile(fileparts(mfilename('fullpath')), 'maps');
    hgt_dir_name = fullfile(fileparts(mfilename('fullpath')), 'hgt');
    
    % stelle sicher dass Verzeichnis existiert
    if ~isdir(map_dir_name)
        mkdir(map_dir_name);
    end
    
    if consider_elevation && ~isdir(hgt_dir_name)
        mkdir(hgt_dir_name);
    end
    
    sackgassen_uuid = zeros(1,0);
    ist_sackgasse = false;
    
    wbh = waitbar(0, 'Berechne Route ...');
    
    % Abbruchbedingung: für 24h gelaufen oder Sonne untergegangen
    while visible && t < t_end
        % interpretiere die Laufzeit-Pause-Liste als zyklisch
        pidx = mod(pauseidx - 1, fnpperiod) + 1;
        
        % überprüfe, ob wir Pause machen wollen
        if t - endlastbreak > fitness.walkpause(1, pidx)
            t = t + fitness.walkpause(2, pidx);
            endlastbreak = t;
            pauseidx = pauseidx + 1;
            
            step = step + 1;
            X(:, step) = X(:, step-1);
            N(1, step) = N(1, step-1);
            T(1, step) = t;
            D(1, step) = D(1, step-1);
            E(1, step) = E(1, step-1);
            continue;
        end
        
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0007
            % Statusupdate
            waitbar((t-T(1))/day_dur, wbh, ...
                sprintf('Berechne Route ... (%d Karten verwendet)', maps_used));
            
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            
            % suche nach .osm Dateien im Unterverzeichnis maps
            osm_files = dir(fullfile(map_dir_name, '*.mat'));
            numfiles = size(osm_files, 1);
            
            fprintf('[%3d]', maps_used);
            
            if numfiles > 0
                map_bounds = zeros(numfiles, 4);
                map_dist = zeros(1, numfiles);
                for i = 1:numfiles
                    % parse Bounding Box aus Dateinamen heraus; transponieren!
                    map_bounds(i, :) = sscanf(osm_files(i).name, map_filename_spec)';
                    
                    % Distanz zu Grenzen der Bounding Box (Unendlich-Norm)
                    map_dist(1, i) = boundaryDistance(coord, map_bounds(i, :));
                end
                
                % wollen Karte, in der jetzige Koordinaten am 'innersten' liegen
                [max_dist, dist_idx] = max(map_dist);
                
                % Startpunkt liegt innerhalb lokaler Karte und liegt nicht zu nah an der
                % Grenze
                if max_dist > 0.001
                    local_map_found = true;
                    filename = fullfile(map_dir_name, osm_files(dist_idx).name);
                    bounds = map_bounds(dist_idx, :);
                    
                    loadedvar = load(filename, 'parsed_osm');
                    parsed_osm = loadedvar.parsed_osm;
                    
                    fprintf('[L]');
                end
            end
            
            % haben keine geeignete Karte lokal gespeichert
            if ~local_map_found
                bounds = [lat-br_lat lon-br_lon lat+br_lat lon+br_lon];
                % sende Anfrage an Overpass-API
                apistr = { 'http://overpass-api.de/api', ...
                    'http://overpass.osm.rambler.ru/cgi/' };
                api_name = sprintf(...
                    '%s/interpreter?data=[bbox:%f,%f,%f,%f];(way["highway"];>;);out;', ...
                    apistr{1}, bounds);

                fprintf('[Q ');
                tic;
                % größere Anfragen brauchen ggf. länger, Default-Timeout von 5sec ist zu
                % kurz
                options = weboptions('Timeout', 25);
                % Verbindungsfehler abfangen
                try
                    remote_xml = webread(api_name, options);
                catch ME
                    fprintf('ERROR]\n');
                    errordlg(getReport(ME, 'extended', 'hyperlinks', 'off'), 'Fehler');
                    close(wbh);
                    [~] = toc;
                    rethrow(ME);
                end
                time = toc;

                fprintf('%9.6f s]', time);

                % Generiere (weitestgehend) eindeutigen Dateinamen für Straßendaten und
                % schreibe xml in die Datei
                filename = fullfile(map_dir_name, sprintf(map_filename_spec, bounds));
                
                osmname = fullfile(map_dir_name, 'temp.osm');
                fid = fopen(osmname, 'wt');
                if fid == -1
                    fprintf('\n%s Kann nicht geöffnet werden. Breche ab.\n', osmname);
                    break;
                end
                fprintf(fid, '%s', remote_xml);
                fclose(fid);
                
                clear remote_xml api_name;
            
                % benutze openstreetmapfunctions, um OSM-XML in Matlab-Struct zu
                % parsen
                fprintf('[P ');
                try
                    tic;
                    [parsed_osm, ~] = parse_openstreetmap(osmname);
                    time = toc;
                    fprintf(' %9.6f s]', time);
                catch
                    [~] = toc;
                    fprintf(' ERROR]\n');
                    delete(osmname);
                    break;
                end
                
                delete(osmname);
                save(filename, 'parsed_osm');
            end

            fprintf('[A ');
            tic;
            % Eigene Function für Adjazenzmatrix für ungerichteten Graphen -> symmetrische
            % Matrix
            adj_matrix = adjacencyMatrix(parsed_osm);
            time = toc;
            fprintf('%9.6f s]\n', time);
            
            % muss Index neu bestimmen, da sich zugrundeliegende Daten verändert haben
            % diese Methode ist potentiell ungenau
            node_idx = findNearestVec(coord, parsed_osm.node.xy);
            node_idx_prev = findNearestVec(coord_prev, parsed_osm.node.xy);
            
            X(:, step) = parsed_osm.node.xy(:, node_idx);
            N(1, step) = parsed_osm.node.id(node_idx);
            
            % Kümmern uns um Höhendaten, falls gewünscht
            if consider_elevation && abs(coord(2)) < 60
                R = readhgt(bounds([1 3 2 4]) + [-0.2, 0.2, -0.2, 0.2], ...
                    'interp', 'outdir', hgt_dir_name, ...
                    'url', 'https://dds.cr.usgs.gov/srtm/version2_1');
                E(1, step) = get_elevation(lon, lat);
            end
        end
        
        step = step + 1;
        
        speed = fitness.f{mod(pauseidx - 1, fnfperiod) + 1}(t - endlastbreak);
        
        % Indizes aller adjazenten Knoten
        neighbor_idxs = find(adj_matrix(:, node_idx));
        [~, remove_idxs, ~] = intersect(parsed_osm.node.id(neighbor_idxs), ...
            sackgassen_uuid);
        neighbor_idxs(remove_idxs) = [];
        num_neighbors = size(neighbor_idxs, 1);
        
        % Betrachte zunächst die Fälle, wenn keine, einer oder genau zwei Nachbarn
        % existieren
        if num_neighbors == 0
            fprintf('Knoten hat keine Nachbarn, die nicht in Sackgasse enden.\n');
            break;
        elseif num_neighbors == 1
            ist_sackgasse = true;
        elseif num_neighbors == 2
            % Gehe Straße entlang, wenn keine Kreuzung.
            neighbor_idxs = neighbor_idxs(neighbor_idxs ~= node_idx_prev);
            num_neighbors = size(neighbor_idxs, 1);
        else
            % Sackgasseneingang merken
            if ist_sackgasse
                sackgassen_uuid(1,end+1) = parsed_osm.node.id(node_idx_prev);
                ist_sackgasse = false;
            end
            
            neighbor_idxs = neighbor_idxs(neighbor_idxs ~= node_idx_prev);
            num_neighbors = size(neighbor_idxs, 1);
            
            %remember_intersections = 3;
            
            % Zykelprävention
            lastvisited_idx = find(N(1, 1:end-1) == N(1, end));
            idx = numel(lastvisited_idx);
            
            % prüfe, ob genug Distanz seit letztem Besuch zurückgelegt wurde
            while idx > 0 && lastvisited_idx(idx) > 1 && ...
                    num_neighbors > 1 && ...
                    D(1, end) - D(1, lastvisited_idx(idx)) < 2000
                % prüfe, ob wir uns in gleicher Konfiguration befinden
                if N(end-1) == N(lastvisited_idx(idx)-1)
                    % entferne damals ausgesuchten Nachbar als Option
                    neighbor_idxs = neighbor_idxs(neighbor_idxs ~= ...
                        find(parsed_osm.node.id == N(1, lastvisited_idx(idx)+1, 1)));
                    num_neighbors = size(neighbor_idxs, 1);
                end
                
                idx = idx - 1;
            end
        end
            
        % benutze bereits geschriebene Funktion earth_path um die optimale nächste
        % Position zu bestimmen
        [visible, p_optimal] = earth_path(p, t, delta_t, speed, earth_radius);

        % betrachte relative Bewegungsrichtung, normiere
        richtung_optimal = (p_optimal - p)/norm(p_optimal - p);

        % wollen Bewegungen in Richtung der Nachbarsknoten bestimmen
        vec_neighbor = zeros(3, num_neighbors);
        dot_neighbor = zeros(1, num_neighbors);

        for i = 1:num_neighbors
            % bestimme 3d-Position und normalisierte Gang-Richtung für jeden
            % adjazenten Knoten
            vec_neighbor(:, i) = osmnode2vec(neighbor_idxs(i));

            norm_neighbor = norm(vec_neighbor(:,i) - p);

            % sollte nicht auftreten
            if norm_neighbor == 0
                r_neighbor = zeros(3,1);
            else
                r_neighbor = (vec_neighbor(:,i) - p)/norm_neighbor;
            end

            % Skalarprodukt, um Kolinearität der Richtungen zu ermitteln
            dot_neighbor(1,i) = dot(richtung_optimal, r_neighbor);
        end

        % bestmöglicher nächster Knoten
        [~, max_index] = max(dot_neighbor);
        
        distance_step = norm(vec_neighbor(:,max_index) - p);
        
        % distance_step sollte nicht null sein
        if distance_step > 0
            node_idx_prev = node_idx;
            node_idx = neighbor_idxs(max_index);

            p = vec_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_idx);
            lon = coord(1); lat = coord(2);
        
            % Finde Höhendaten für derzeitige Position
            % Beachte, dass für |LAT| >= 60 keine solchen vorliegen
            if consider_elevation && abs(coord(2)) < 60
                E(1, step) = get_elevation(lon, lat);
                speed = (speed/6) * tobler( (E(step) - E(step-1))/distance_step );
            else
                E(1, step) = 0;
            end

            t = t + distance_step/speed;
        else
            % Lasse zeit verstreichen, tue sonst nichts
            t = t + delta_t;
            distance_step = 0;
            E(1, step) = E(1, step-1);
        end
        
        X(:, step) = coord;
        N(1,step) = parsed_osm.node.id(node_idx);
        T(1,step) = t;
        D(1,step) = D(1,step-1) + distance_step;
    end
    
    close(wbh);
    
    fprintf('\nFertig.\n');
    
    % Abstand eines Vektors c zum Komplement der Rechtecksfläche gegeben durch bnd in der
    % Unendlich-Norm
    function d = boundaryDistance(c, bnd)
        if any(c' < bnd([2 1])) || any(c' > bnd([4 3]))
            d = 0;
        else
            d = min(abs(bnd([2 1 4 3]) - repmat(c', 1, 2)));
        end
    end

    % konvertiere Node-Index in einen 3D-Vektor
    function pt = osmnode2vec(idx)
        pt = lonlat2vec(parsed_osm.node.xy(1, idx), ...
            parsed_osm.node.xy(2, idx), earth_radius);
    end
    
    % Toblers Wanderfunktion in km/h
    function v = tobler(slope)
        v = 6 * exp( (-3.5) * abs(slope + 0.05));
    end
    
    % interpoliere Höhe aus 4 umliegenden Punkten
    % verkleinern der Eingabe erhöht Performance von interp2 _immens_
    function elev = get_elevation(lon, lat)
        idxlat = findNearest(lat, R.lat);
        idxlon = findNearest(lon, R.lon);
        rLat = max(1, idxlat-1):min(size(R.lat, 1), idxlat+1);
        rLon = max(1, idxlon-1):min(size(R.lon, 2), idxlon+1);
        elev = interp2(R.lat(rLat), R.lon(rLon), double(R.z(rLat, rLon)'), lat, lon);
    end
end
