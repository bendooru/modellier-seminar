function [X, ax] = follow_osm(lon, lat, delta_t, speed, tag)
    % lon, lat Startkoordinaten,
    % delta_t Zeitdifferenz der Schritte
    
    % muss Spaltenvektor sein!
    coord = [lon; lat];
    earth_radius = 6371000;
    
    % Werte initialisieren
    p = lonlat2vec(lon, lat, earth_radius);
    [t, visible] = sonnenaufgang(p, tag);
    % maximal einen Tag lang
    t_end = t + 1440;
    
    % initialisiere Arrays leer, werden dynamisch vergrößert.
    % Folge der besuchten Koordinaten
    X = zeros(2,0);
    % betrachtete Zeitpunkte
    T = zeros(1,0);
    % zurückgelegte Distanz
    D = zeros(1,0);
    
    % Abstand zu Grenzen in Längen-/Breitengraden
    br_lat = 0.008;
    br_lon = 0.012;
    
    % Initialisiere Bounding Box als Punkt
    bounds = [lat lon lat lon];
    
    step = 1;
    
    node_idx_prev = -1;
    coord_prev = [0;0];
    
    maps_used = 0;
    
    % figure in die die Karte geplottet wird
    fig = figure;
    ax = axes('Parent', fig);
    hold(ax, 'on');
    
    map_filename_spec = 'map-%f_%f_%f_%f.osm';
    
    % Abbruchbedingung: für 24h gelaufen oder Sonne untergegangen
    while t < t_end && visible
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0005
            % Distanz zu Grenze ist gering, lade neue Karte
            maps_used = maps_used + 1;
            local_map_found = false;
            % suche nach .osm Dateien im Unterverzeichnis maps
            osm_files = dir('maps/*.osm');
            
            numfiles = size(osm_files, 1);
            
            if numfiles > 0
                map_bounds = zeros(numfiles, 4);
                map_dist = zeros(1, numfiles);
                for i = 1:numfiles
                    % parse Bounding Box aus Dateinamen heraus; transponieren!
                    map_bounds(i, :) = sscanf(osm_files(i).name, ...
                        map_filename_spec)';
                    
                    % Distanz zu Grenzen der Bounding Box (Unendlich-Norm)
                    map_dist(1, i) = boundaryDistance(coord, map_bounds(i, :));
                end
                
                % wollen Karte, in der jetzige Koordinaten am 'innersten' liegen
                [maxd, didx] = max(map_dist);
                
                % Startpunkt liegt innerhalb lokaler Karte und liegt nicht zu
                % nah an der Grenze
                if maxd > 0.001
                    local_map_found = true;
                    filename = sprintf('maps/%s', osm_files(didx).name);
                    bounds = map_bounds(didx, :);
                    
                    fprintf('[%2d] Local map found.\n', maps_used);
                    fprintf('   > Filename is %s.\n', filename);
                end
            end
            
            % haben keine geeignete Karte lokal gespeichert
            if ~local_map_found
                bounds = [lat-br_lat lon-br_lon lat+br_lat lon+br_lon];
                api_name = sprintf(...
                    '%s/api/interpreter?data=(way["highway"](%f,%f,%f,%f);>;);out;', ...
                    'http://overpass-api.de', bounds);

                tic;
                % größere Anfragen brauchen ggf. länger, Default-Timeout von
                % 5sec ist zu kurz
                remote_xml = webread(api_name, 'Timeout', 20);
                time = toc;

                fprintf('[%2d] API query completed.        [%9.6f s]\n', ...
                    maps_used, time);

                % finde ersten <node>-Tag in xml-Daten
                indices = strfind(remote_xml, '<node');
                if size(indices, 2) == 0
                    warning('OSM Data does not appear to contain nodes!');
                    break;
                end
                idx_xml = indices(1);

                % xml-Daten müssen manipuliert werden, um vom Parser akzeptiert zu
                % werden: benötigt ein Bounds-Feld
                remote_xml = sprintf(...
                    '%s<bounds minlat="%f" minlon="%f" maxlat="%f" maxlon="%f"/>\n  %s', ...
                    remote_xml(1:idx_xml-1), bounds, remote_xml(idx_xml:end));

                % Generiere (weitestgehend) eindeutigen Dateinamen für
                % Straßendaten und schreibe xml in die Datei
                filename = fullfile('maps', sprintf(map_filename_spec, bounds));
                fid = fopen(filename, 'wt');
                if fid == -1
                    error('Irgendwas stimmt mit fopen nicht.\n%s wird nicht als filename akzeptiert.', ...
                        filename);
                end
                fprintf(fid, '%s', remote_xml);
                fclose(fid);
                
                fprintf('   > Saving to %s.\n', filename);
            end
            
            % benutze openstreetmapfunctions, um OSM-XML in Matlab-Struct zu
            % parsen
            tic;
            [parsed_osm, ~] = parse_openstreetmap(filename);
            time = toc;
            fprintf('   * Parsed data.                [%9.6f s]\n', time);

            tic;
            % Eigene Function für Adjazenzmatrix
            % extract_connectivity liefert eine unvollständige Matrix
            adj_matrix = adjacencyMatrix(parsed_osm);
            % Symmetrisch machen -> ungerichteter Graph
            % müssen uns so nicht um RIchtung der Wege kümmern
            dg = or(adj_matrix, adj_matrix.');
            time = toc;
            fprintf('   * Created adjacency matrix.   [%9.6f s]\n', time);
            
            % muss Index neu bestimmen, da sich zugrundeliegende Daten verändert
            % haben
            node_idx = findNearestVec(coord, parsed_osm.node.xy);
            node_idx_prev = findNearestVec(coord_prev, parsed_osm.node.xy);
            
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
        neighbor_idxs = find(dg(:, node_idx));
        num_neighbors = size(neighbor_idxs, 1);
        
        % benutze bereits geschriebene Funktion um die optimale Laufrichtung
        % Richtung Sonne zu bestimmen
        [richtung_optimal, visible] = ...
            earth_path(p, t, delta_t, speed, earth_radius);
        
        % normiere
        richtung_optimal = (richtung_optimal - p)/norm(richtung_optimal-p);
        
        % wollen 3d-Richtungen in Richtung der Nachbarsknoten bestimmen
        richtung_neighbor = zeros(3, num_neighbors);
        colinear_neighbor = zeros(1, num_neighbors);
        
        for i = 1:num_neighbors
            % bestimme 3d-Position und normalisierte Gang-Richtung für jeden
            % adjazenten Knoten
            richtung_neighbor(:, i) = osmnode2vec(neighbor_idxs(i));
            
            norm_neighbor = norm(richtung_neighbor(:,i) - p);
            if norm_neighbor == 0
                r_neighbor = zeros(3,1);
            else
                r_neighbor = (richtung_neighbor(:,i) - p)/norm_neighbor;
            end
            
            % Skalarprodukt, um Kolinearität der Richtungen zu ermitteln
            colinear_neighbor(1,i) = dot(richtung_optimal, r_neighbor);
        end
        
        [max_colinear, max_index] = max(colinear_neighbor);
            
        step = step + 1;
        
        % Gehe Straße einfach weiter, wenn keine Kreuzung
        % für step == 2 ist node_id_prev nicht sinnvoll initialisiert, also
        % übergehe diesen Fall
        if num_neighbors == 2 && step > 2
            node_id_new = neighbor_idxs(neighbor_idxs ~= node_idx_prev);
            node_idx_prev = node_idx;
            node_idx = node_id_new;
            
            distance = norm(richtung_neighbor(:,max_index) - p);
            p = richtung_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_idx);
            lon = coord(1); lat = coord(2);
            
            t = t + distance/speed;
        % Nächstbeste Straße sollte nicht von Sonne weg führen
        % fängt gleichzeitig 'Bewegungen' mit Distanz 0 ab
        elseif max_colinear > 0
            node_idx_prev = node_idx;
            node_idx = neighbor_idxs(max_index);
            
            distance = norm(richtung_neighbor(:,max_index) - p);
            p = richtung_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_idx);
            lon = coord(1); lat = coord(2);
            
            t = t + distance/speed;
        else
            t = t + delta_t;
            distance = 0;
        end
        
        X(:, step) = coord;
        T(1,step) = t;
        D(1,step) = D(1,step-1) + distance;
    end
    
    % Plotte gefundene Route
    plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 2);
    hold(ax, 'off');
    xlabel(ax, 'Longitude');
    ylabel(ax, 'Latidude');
    
    % Plotte zurückgelegte Distanz über Zeit
    % bisher: bleiben zu oft in Sackgassen etc hängen; teilweise über mehrere
    % Stunden hinweg
    figure; plot((T - T(1,1))./60, D./1000);
    xlabel('Time [h]');
    ylabel('Distance [km]');
    
    % Abstand eines Vektors c zum Komplement der Rechtecksfläche gegeben durch
    % bnd in der Unendlich-Norm
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