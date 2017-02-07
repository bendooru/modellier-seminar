function [X, D, T] = follow_osm_free(lon, lat, delta_t, tag, fitness, varargin)
    % Funktion berechnet Route entlang Straßen und Wegen, wenn Sonne hinterhergelaufen
    % wird
    
    % muss Spaltenvektor sein!
    coord = [lon; lat];
    earth_radius = 6371000;
    
    % Werte initialisieren
    p = lonlat2vec(lon, lat, earth_radius);
    [t, visible, t_unter] = sonnenaufgang(p, tag);
    % maximal einen Tag lang
    t_end = t + 1440;
    day_dur = t_unter - t;
    
    % initialisiere Arrays leer, werden dynamisch vergrößert:
    % Folge der besuchten Koordinaten, betrachtete Zeitpunkte und zurückgelegte Distanz
    X = coord;
    T = t;
    D = zeros(1, 0); D(1, 1) = 0;
    E = zeros(1, 0); E(1,1) = 0;
    
    lineplot = any(strcmpi(varargin, 'LinePlot'));
    if lineplot
        fig = figure;
        ax = axes('Parent', fig);
        daspect(ax, [1, 0.4725, 1]);
        hold(ax, 'on');
    end
    
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
    br_lat = 0.003;
    br_lon = 0.003;
    
    % Initialisiere Bounding Box als Punkt
    bounds = [lat lon lat lon];
    
    step = 1;
    
    maps_used = 0;
    ausweichen = false;
    
    % Format für Karten-Dateinamen
    map_filename_spec = 'map-%f_%f_%f_%f.osm';
    map_dir_name = 'maps-free';
    
    if ~isdir(map_dir_name)
        mkdir(map_dir_name);
    end
    
    if consider_elevation && ~isdir('hgt')
        mkdir('hgt');
    end
    
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
            T(1, step) = t;
            D(1, step) = D(1, step-1);
            E(1, step) = E(1, step-1);
            continue;
        end
        
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0005
            % Statusupdate
            waitbar((t-T(1, 1))/day_dur, wbh, ...
                sprintf('Berechne Route ... (%d Karten verwendet)', maps_used));
            
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            map_nonempty = true;
            
            % suche nach .osm Dateien im Unterverzeichnis maps
            osm_files = dir(fullfile(map_dir_name, '*.osm'));
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
                if max_dist > 0.0008
                    local_map_found = true;
                    filename = fullfile(map_dir_name, osm_files(dist_idx).name);
                    bounds = map_bounds(dist_idx, :);
                    
                    fprintf('[L]');
                end
            end
            
            % haben keine geeignete Karte lokal gespeichert
            if ~local_map_found
                bounds = [coord(2)-br_lat coord(1)-br_lon coord(2)+br_lat coord(1)+br_lon];
                
                % sende Anfrage an Overpass-API
                api_request = [ '((', ...
                    'way["building"];', ...
                    'way["barrier"];', ...
                    'way["natural"="water"];', ...
                    'way["natural"="coastline"];', ...
                    'way["waterway"="riverbank"];', ...
                    ');>;);out;'; ];
                apistr = { 'http://overpass-api.de/api', ...
                    'http://overpass.osm.rambler.ru/cgi/' };
                api_name = sprintf(...
                    '%s/interpreter?data=[bbox:%f,%f,%f,%f];%s', ...
                    apistr{2}, bounds, api_request);

                fprintf('[Q ');
                tic;
                % größere Anfragen brauchen ggf. länger, Default-Timeout von 5sec ist zu
                % kurz
                options = weboptions('Timeout', 20);
                % Verbindungsfehler abfangen
                try
                    remote_xml = webread(api_name, options);
                catch
                    fprintf('ERROR]\n');
                    [~] = toc;
                    break;
                end
                time = toc;

                fprintf('%9.6f s]', time);

                % Generiere (weitestgehend) eindeutigen Dateinamen für Straßendaten und
                % schreibe xml in die Datei
                filename = fullfile(map_dir_name, sprintf(map_filename_spec, bounds));
                fid = fopen(filename, 'wt');
                if fid == -1
                    error('%s kann nicht geöffnet werden.', filename);
                end
                fprintf(fid, '%s', remote_xml);
                fclose(fid);
                
                clear remote_xml api_name;
            end
            
            % benutze openstreetmapfunctions, um OSM-XML in Matlab-Struct zu
            % parsen
            fprintf('[P ');
            try
                tic;
                [parsed_osm, ~] = parse_openstreetmap(filename);
                time = toc;
                fprintf('%9.6f s]\n', time);
            catch
                [~] = toc;
                fprintf(' E]');
                map_nonempty = false;
            end
            
            % Kümmern uns um Höhendaten, falls gewünscht
            if consider_elevation && abs(coord(2)) < 60
                R = readhgt(bounds([1 3 2 4]) + [-0.2, 0.2, -0.2, 0.2], ...
                    'interp', 'outdir', 'hgt', ...
                    'url', 'https://dds.cr.usgs.gov/srtm/version2_1');
                E(1, step) = get_elevation(coord(1), coord(2));
            end
            
            if lineplot && map_nonempty 
                plot_streets(ax, parsed_osm);
            end
        end
        
        % Beginne Berechnung
        step = step + 1;
        
        speed = fitness.f{mod(pauseidx - 1, fnfperiod) + 1}(t - endlastbreak);
        
        p_prev = p;
        [visible, p] = earth_path(p, t, delta_t, speed, earth_radius);
        [coord(1), coord(2), ~] = cart2sph(p(1), p(2), p(3));
        coord = rad2deg(coord);
        
        if ausweichen
            if dot(collision_dir, coord - X(:, step-1)) < 0
                collision_dir = -collision_dir;
            end
            
            coordTemp = X(:, step-1) + collision_dir;
            dist = norm(p_prev - lonlat2vec(coordTemp(1), coordTemp(2), earth_radius));
            
            coord = X(:, step-1) + (speed*delta_t) .* collision_dir/dist;
            p = lonlat2vec(coord(1), coord(2), earth_radius);
            
            distance = norm(p-p_prev);
        else
            distance = speed*delta_t;
        end
        
        if map_nonempty
            % überprüfe auf Kollisionen
            collision = Inf;
            collision_dir = [0;0];
            
            for way = parsed_osm.way.nd
                waysize = size(way{1}, 2);
                wayxy = zeros(2, waysize);
                for ndi = 1:waysize
                    wayxy(:, ndi) = parsed_osm.node.xy(:, ...
                        parsed_osm.node.id == way{1}(1, ndi));
                end
                
                for ndi = 2:waysize
                    % Prüfe mit linearer Algebra, ob wir einen way übertreten
                    A = [coord-X(:,step-1), wayxy(:,ndi-1)-wayxy(:,ndi)];
                    
                    if rcond(A) < 1e-22
                        % Laufen nahezu parallel zu betrachtetem Wegsegment
                        continue;
                    end
                    
                    b = wayxy(:,ndi-1) - X(:,step-1);
                    sol = A\b;
                    
                    % Kollision liegt auf dem Laufweg
                    if all(sol >= 0) && all(sol <= 1) && sol(1) < collision
                        collision = sol(1);
                        collision_dir = wayxy(:, ndi) - wayxy(:, ndi-1);
                    end
                end
            end
            if collision <= 1
                %coeff = norm(lonlat2vec(coord(1), coord(2), earth_radius) ...
                %   -lonlat2vec(X(1, step-1), X(2, step-1), earth_radius)) * collision;
                %coeff = max(0, coeff-1)/coeff;
                coeff = 0.9 * collision;
                coord = (coord - X(:,step-1)) * coeff + X(:,step-1);
                p = lonlat2vec(coord(1), coord(2), earth_radius);
                
                distance = distance * coeff;
                
                ausweichen = true;
            else
                ausweichen = false;
            end
        end
        
        % Finde Höhendaten für derzeitige Position
        % Beachte, dass für |LAT| >= 60 keine solchen vorliegen
        if consider_elevation && abs(coord(2)) < 60
            E(1, step) = get_elevation(coord(1), coord(2));
            speed = (speed/6) * tobler( (E(step) - E(step-1))/distance );
        else
            E(1, step) = 0;
        end
        
        % Falls Bewegung zu wenig Zeit benötigt, lass delta_t Minuten verstreichen
        if distance/speed < 0.1*delta_t
            t = t + delta_t;
        else
            t = t + distance/speed;
        end
        
        X(:, step) = coord;
        T(step) = t;
        D(1, step) = D(1, step-1) + distance;
    end
    
    close(wbh);
    
    if lineplot
        plot(X(1, :), X(2, :), 'r', 'LineWidth', 1.5);
    end
    
    fprintf('Fertig.\n');
    
    % Abstand eines Vektors c zum Komplement der Rechtecksfläche gegeben durch bnd in der
    % Unendlich-Norm
    function d = boundaryDistance(c, bnd)
        if any(c' < bnd([2 1])) || any(c' > bnd([4 3]))
            d = 0;
        else
            d = min(abs(bnd([2 1 4 3]) - repmat(c', 1, 2)));
        end
    end
    
    % Toblers Wanderfunktion in km/h
    function v = tobler(slope)
        v = 6 * exp((-3.5) * abs(slope + 0.05));
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