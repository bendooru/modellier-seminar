function [X, ax] = follow_osm_free(lon, lat, delta_t, speed, tag)
    % Funktion berechnet Route entlang Straßen und Wegen, wenn Sonne hinterhergelaufen
    % wird
    % übergib 'TimePlot' als letztes Argument, um Distanz/Zeit zu plotten
    
    % muss Spaltenvektor sein!
    coord = [lon; lat];
    earth_radius = 6371000;
    
    % Werte initialisieren
    p = lonlat2vec(lon, lat, earth_radius);
    [t, visible] = sonnenaufgang(p, tag);
    % maximal einen Tag lang
    t_end = t + 1440;
    
    % initialisiere Arrays leer, werden dynamisch vergrößert:
    % Folge der besuchten Koordinaten, betrachtete Zeitpunkte und zurückgelegte Distanz
    X = coord;
    T = t;
    D = 0;
    
    % Abstand zu Grenzen in Längen-/Breitengraden
    br_lat = 0.004;
    br_lon = 0.006;
    
    % Initialisiere Bounding Box als Punkt
    bounds = [lat lon lat lon];
    
    step = 1;
    
    maps_used = 0;
    
    % figure in die die Karte geplottet wird
    fig = figure;
    ax = axes('Parent', fig);
    axis(ax, 'equal');
    hold(ax, 'on');
    
    % Format für Karten-Dateinamen
    map_filename_spec = 'map-%f_%f_%f_%f.osm';
    map_dir_name = 'maps-free';
    
    if ~isdir(map_dir_name)
        mkdir(map_dir_name);
    end
    
    % Abbruchbedingung: für 24h gelaufen oder Sonne untergegangen
    while visible && t < t_end
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0005
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            map_nonempty = true;
            
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
                if max_dist > 0.0008
                    local_map_found = true;
                    filename = fullfile(map_dir_name, osm_files(dist_idx).name);
                    bounds = map_bounds(dist_idx, :);
                    
                    fprintf('[%3d] Local map found.\n', maps_used);
                    fprintf('    > Filename is %s.\n', filename);
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
                    'way["waterway"];', ...
                    ');>;);out;'; ];
                api_name = sprintf(...
                    '%s/api/interpreter?data=[bbox:%f,%f,%f,%f];%s', ...
                    'http://overpass-api.de', bounds, api_request);

                fprintf('[%3d] Querying API ... ', maps_used);
                tic;
                % größere Anfragen brauchen ggf. länger, Default-Timeout von 5sec ist zu
                % kurz
                options = weboptions('Timeout', 20);
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
                    error('%s konnte nicht geöffnet werden.', filename);
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
                fprintf('empty map.\n');
                map_nonempty = false;
            end
        end
        
        % Beginne Berechnung
        step = step + 1;
        
        [p, visible] = earth_path(p, t, delta_t, speed, earth_radius);
        [coord(1), coord(2), ~] = cart2sph(p(1), p(2), p(3));
        coord = rad2deg(coord);
        
        if map_nonempty
            % überprüfe auf Kollisionen
            collision_found = false;
            
            for way = parsed_osm.way.nd
                waysize = size(way{1}, 2);
                wayxy = zeros(2, waysize);
                for ndi = 1:waysize
                    wayxy(:, ndi) = parsed_osm.node.xy(:, ...
                        parsed_osm.node.id == way{1}(1, ndi));
                end
                
                for ndi = 1:waysize
                    % Prüfe mit linearer Algebra, ob wir einen way übertreten
                    if ndi == 1
                        ndi_prev = waysize;
                    else
                        ndi_prev = ndi - 1;
                    end
                    
                    A = [coord-X(:,step-1), wayxy(:,ndi_prev)-wayxy(:,ndi)];
                    
                    if det(A) == 0
                        % Laufen parallel zu betrachtetem Wegsegment
                        continue;
                    end
                    
                    b = wayxy(:,ndi_prev) - X(:,step-1);
                    sol = A\b;
                    
                    % Kollision liegt auf dem Laufweg
                    if sol(1) >= 0 && sol(1) <= 1
                        coord = (coord - X(:,step-1))*sol(1) + X(:,step-1);
                        p = lonlat2vec(coord(1), coord(2), earth_radius);
                        collision_found = true;
                        break;
                    end
                end
                
                if collision_found
                    break;
                end
            end
        end
        
        t = t + delta_t;
        
        X(:, step) = coord;
        T(step) = t;
        D(step) = D(step-1) + speed*delta_t;
    end
    
    % Plotte gefundene Route
    fprintf('\nFinished calculating route, plotting ... ');
    plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 2);
    hold(ax, 'off');
    xlabel(ax, 'Longitude (°)');
    ylabel(ax, 'Latidude (°)');
    title(ax, datestr(datetime('2000-12-31') + tag, 'mmmm dd'));
    fprintf('done.\n');
    
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
end