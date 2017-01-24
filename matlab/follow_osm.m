function [X, D, T] = follow_osm(lon, lat, delta_t, tag, fitness, wbh, varargin)
    % Funktion berechnet Route entlang Straßen und Wegen, wenn Sonne hinterhergelaufen
    % wird
    % optionale Argumente:
    % * 'NoElevation': ohne Höhendaten rechnen
    
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
        fprintf('Array specifiying walkling/pausing times has incorrect size');
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
    map_filename_spec = 'map-%f_%f_%f_%f.osm';
    map_dir_name = 'maps';
    
    % stelle sicher dass Verzeichnis existiert
    if ~isdir(map_dir_name)
        mkdir(map_dir_name);
    end
    
    if consider_elevation && ~isdir('hgt')
        mkdir('hgt');
    end
    
    sackgassen_uuid = zeros(1,0);
    ist_sackgasse = false;
    
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
                sprintf('Calculating route ... (%d maps used)', maps_used));
            
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            
            % suche nach .osm Dateien im Unterverzeichnis maps
            osm_files = dir(fullfile(map_dir_name, '*.osm'));
            numfiles = size(osm_files, 1);
            
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
                    
                    fprintf('[%3d] Local map found.\n', maps_used);
                    fprintf('    > Filename is %s.\n', filename);
                end
            end
            
            % haben keine geeignete Karte lokal gespeichert
            if ~local_map_found
                bounds = [lat-br_lat lon-br_lon lat+br_lat lon+br_lon];
                % sende Anfrage an Overpass-API
                api_name = sprintf(...
                    '%s/api/interpreter?data=[bbox:%f,%f,%f,%f];(way["highway"];>;);out;', ...
                    'http://overpass-api.de', bounds);

                fprintf('[%3d] Querying API ... ', maps_used);
                tic;
                % größere Anfragen brauchen ggf. länger, Default-Timeout von 5sec ist zu
                % kurz
                options = weboptions('Timeout', 25);
                % Verbindungsfehler abfangen
                try
                    remote_xml = webread(api_name, options);
                catch
                    fprintf('failed. Aborting calculation.\n');
                    [~] = toc;
                    break;
                end
                time = toc;

                fprintf('done.                     [%9.6f s]\n', time);

                % Generiere (weitestgehend) eindeutigen Dateinamen für Straßendaten und
                % schreibe xml in die Datei
                filename = fullfile(map_dir_name, sprintf(map_filename_spec, bounds));
                fid = fopen(filename, 'wt');
                if fid == -1
                    fprintf('%s cannot be opened as a file. Aborting.\n', filename);
                    break;
                end
                fprintf(fid, '%s', remote_xml);
                fclose(fid);
                
                clear remote_xml api_name;
                
                fprintf('    > Saving to %s.\n', filename);
            end
            
            % benutze openstreetmapfunctions, um OSM-XML in Matlab-Struct zu
            % parsen
            fprintf('    * Parsing data ... ');
            try
                tic;
                [parsed_osm, ~] = parse_openstreetmap(filename);
                time = toc;
                fprintf('done.                     [%9.6f s]\n', time);
            catch
                [~] = toc;
                fprintf('failed.\n');
                break;
            end

            fprintf('    * Creating adjacency matrix ... ');
            tic;
            % Eigene Function für Adjazenzmatrix für ungerichteten Graphen -> symmetrische
            % Matrix
            adj_matrix = adjacencyMatrix(parsed_osm);
            time = toc;
            fprintf('done.        [%9.6f s]\n', time);
            
            % muss Index neu bestimmen, da sich zugrundeliegende Daten verändert haben
            % diese Methode ist potentiell ungenau
            node_idx = findNearestVec(coord, parsed_osm.node.xy);
            node_idx_prev = findNearestVec(coord_prev, parsed_osm.node.xy);
            
            X(:, step) = parsed_osm.node.xy(:, node_idx);
            N(1, step) = parsed_osm.node.id(node_idx);
            
            % Kümmern uns um Höhendaten, falls gewünscht
            if consider_elevation
                R = readhgt(bounds([1 3 2 4]) + [-0.2, 0.2, -0.2, 0.2], ...
                    'interp', 'outdir', 'hgt', ...
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
            fprintf('Node has no non-dead end neighbors.\n');
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
            
            % Zykelprävention
            lastvisited_idx = find(N(1, 1:end-1) == N(1, end), 1, 'last');
            % prüfe, ob Knoten bereits einmal besucht
            if isscalar(lastvisited_idx)
                % prüfe, ob genug Distanz seit letztem Besuch zurückgelegt wurde
                if lastvisited_idx > 1 && D(1, end) - D(1, lastvisited_idx) < 1000
                    % prüfe, ob wir uns in gleicher Konfiguration befinden
                    if N(end-1) == N(lastvisited_idx-1)
                        % entferne damals ausgesuchten Nachbar als Option
                        neighbor_idxs = neighbor_idxs(neighbor_idxs ~= ...
                            find(parsed_osm.node.id==N(1, lastvisited_idx+1, 1)));
                        num_neighbors = size(neighbor_idxs, 1);
                    end
                end
            end
        end
            
        % benutze bereits geschriebene Funktion earth_path um die optimale nächste
        % Position zu bestimmen
        [p_optimal, visible] = earth_path(p, t, delta_t, speed, earth_radius);

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
        
        if distance_step > 0
            node_idx_prev = node_idx;
            node_idx = neighbor_idxs(max_index);

            p = vec_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_idx);
            lon = coord(1); lat = coord(2);
        
            if consider_elevation
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
    
    fprintf('\nFinished calculating route.\n');
    
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
    function elev = get_elevation(lon, lat)
        elev = interp2(R.lat, R.lon, double(R.z'), lat, lon);
    end
end
