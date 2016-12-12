function [X, ax] = follow_osm(lon, lat, delta_t, speed, tag)
    % Funktion berechnet Route entlang Straßen und Wegen, wenn Sonne hinterhergelaufen
    % wird
    
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
    X = zeros(2,0);
    T = zeros(1,0);
    D = zeros(1,0);
    
    % Abstand zu Grenzen in Längen-/Breitengraden
    br_lat = 0.008;
    br_lon = 0.012;
    
    % Initialisiere Bounding Box als Punkt
    bounds = [lat lon lat lon];
    
    step = 1;
    
    prev_init = false;
    
    maps_used = 0;
    
    % figure in die die Karte geplottet wird
    fig = figure;
    ax = axes('Parent', fig);
    axis(ax, 'equal');
    hold(ax, 'on');
    
    % Format für Karten-Dateinamen
    map_filename_spec = 'map-%f_%f_%f_%f.osm';
    
    if ~isdir('maps')
        mkdir('maps');
    end
    
    % Abbruchbedingung: für 24h gelaufen oder Sonne untergegangen
    while visible && t < t_end
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0009
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            
            % suche nach .osm Dateien im Unterverzeichnis maps
            osm_files = dir(fullfile('maps', '*.osm'));
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
                    filename = fullfile('maps', osm_files(dist_idx).name);
                    bounds = map_bounds(dist_idx, :);
                    
                    fprintf('[%2d] Local map found.\n', maps_used);
                    fprintf('   > Filename is %s.\n', filename);
                end
            end
            
            % haben keine geeignete Karte lokal gespeichert
            if ~local_map_found
                bounds = [lat-br_lat lon-br_lon lat+br_lat lon+br_lon];
                % sende Anfrage an Overpass-API
                api_name = sprintf(...
                    '%s/api/interpreter?data=(way["highway"](%f,%f,%f,%f);>;);out;', ...
                    'http://overpass-api.de', bounds);

                fprintf('[%2d] Querying API ... ', maps_used);
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

                % finde ersten <node>-Tag in xml-Daten
                indices = strfind(remote_xml, '<node');
                if size(indices, 2) == 0
                    warning('OSM Data does not appear to contain nodes!');
                    break;
                end
                idx_xml = indices(1);

                % xml-Daten müssen manipuliert werden, um vom Parser akzeptiert zu werden:
                % benötigt ein <bounds>-Feld
                remote_xml = sprintf(...
                    '%s<bounds minlat="%f" minlon="%f" maxlat="%f" maxlon="%f"/>\n  %s', ...
                    remote_xml(1:idx_xml-1), bounds, remote_xml(idx_xml:end));

                % Generiere (weitestgehend) eindeutigen Dateinamen für Straßendaten und
                % schreibe xml in die Datei
                filename = fullfile('maps', sprintf(map_filename_spec, bounds));
                fid = fopen(filename, 'wt');
                if fid == -1
                    error('%s konnte nicht geöffnet werden.', filename);
                end
                fprintf(fid, '%s', remote_xml);
                fclose(fid);
                
                clear remote_xml api_name;
                
                fprintf('   > Saving to %s.\n', filename);
            end
            
            % benutze openstreetmapfunctions, um OSM-XML in Matlab-Struct zu
            % parsen
            fprintf('   * Parsing data ... ');
            tic;
            [parsed_osm, ~] = parse_openstreetmap(filename);
            time = toc;
            fprintf('done.                     [%9.6f s]\n', time);

            fprintf('   * Creating adjacency matrix ... ');
            tic;
            % Eigene Function für Adjazenzmatrix für ungerichteten Graphen -> symmetrische
            % Matrix
            % extract_connectivity liefert eine unvollständige Matrix
            adj_matrix = adjacencyMatrix(parsed_osm);
            time = toc;
            fprintf('done.        [%9.6f s]\n', time);
            
            % muss Index neu bestimmen, da sich zugrundeliegende Daten verändert haben
            % diese Methode ist potentiell ungenau
            node_idx = findNearestVec(coord, parsed_osm.node.xy);
            if prev_init
                node_idx_prev = findNearestVec(coord_prev, parsed_osm.node.xy);
            end
            
            if step == 1
                % im ersten Schritt müssen Daten initialisiert werden
                p = osmnode2vec(node_idx);
                coord = parsed_osm.node.xy(:,node_idx);
                lon = coord(1); lat = coord(2);

                X(:,step) = coord;
                T(step) = t;
                D(step) = 0;
            end
            
            % Geladenes Straßennetz plotten
            plot_streets(ax, parsed_osm);
        end
        
        % Indizes aller adjazenten Knoten
        neighbor_idxs = find(adj_matrix(:, node_idx));
        num_neighbors = size(neighbor_idxs, 1);
        
        % Betrachte zunächst die Fälle, wenn keine oder genau zwei Nachbarn existieren
        % TODO: Fall nur 1 Nachbar (d.h. Sackgasse)
        if num_neighbors == 0
            fprintf('Knoten hat keine Nachbarn!\n');
            break;
        elseif num_neighbors == 2 && prev_init
            % Gehe Straße entlang, wenn keine Kreuzung. Vor erster richtigen Bewegung
            % ist node_idx_prev nicht sinnvoll initialisiert, also übergehe diesen Fall
            node_idx_new = neighbor_idxs(neighbor_idxs ~= node_idx_prev);
            node_idx_prev = node_idx;
            node_idx = node_idx_new;
            
            p_neu = osmnode2vec(node_idx);
            distance_step = norm(p_neu-p);
            
            p = p_neu;
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_idx);
            lon = coord(1); lat = coord(2);
            
            t = t + distance_step/speed;
        else
            % benutze bereits geschriebene Funktion earth_path um die optimale nächste
            % Position zu bestimmen
            [p_optimal, visible] = earth_path(p, t, delta_t, speed, earth_radius);

            % betrachte relative Bewegungsrichtung, normiere
            richtung_optimal = (p_optimal - p)/norm(p_optimal-p);

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

            [max_colinear, max_index] = max(dot_neighbor);

            distance_step = norm(vec_neighbor(:,max_index) - p);
            
            % Nächstbeste Straße sollte nicht von Sonne weg führen. Dies fängt
            % gleichzeitig 'Bewegungen' mit Distanz 0 ab
            if max_colinear > 0 && distance_step > 0
                node_idx_prev = node_idx;
                node_idx = neighbor_idxs(max_index);
                prev_init = true;

                p = vec_neighbor(:,max_index);
                coord_prev = coord;
                coord = parsed_osm.node.xy(:,node_idx);
                lon = coord(1); lat = coord(2);

                t = t + distance_step/speed;
            else
                % Lasse zeit verstreichen, tue sonst nichts
                t = t + delta_t;
                distance_step = 0;
                % zum Debuggen!
                plot(ax, X(1, end), X(2, end), '.k', 'Linewidth', 4);
            end
        end
        
        step = step + 1;
        
        X(:, step) = coord;
        T(1,step) = t;
        D(1,step) = D(1,step-1) + distance_step;
    end
    
    % Plotte gefundene Route
    fprintf('\nFinished calculating route, plotting ... ');
    plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 2);
    hold(ax, 'off');
    xlabel(ax, 'Longitude (°)');
    ylabel(ax, 'Latidude (°)');
    title(ax, datestr(datetime('2000-12-31') + tag, 'mmmm dd'));
    fprintf('done.\n');
    
    % Plotte zurückgelegte Distanz über Zeit
    % bisher: bleiben zu oft in Sackgassen etc hängen;
    if size(T, 2) > 0
        figure;
        plot((T - T(1,1))./60, D./1000);
        xlabel('Time [h]');
        ylabel('Distance [km]');
    end
    
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