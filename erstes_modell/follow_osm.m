function X = follow_osm(lon, lat, delta_t, speed, tag)
    coord = [lon; lat];
    earth_radius = 6371000;
    
    p = lonlat2vec(lon, lat, earth_radius);
    [t, visible] = sonnenaufgang(p, tag);
    % maximal einen Tag lang
    t_end = t + 1440;
    
    % Folge der besuchten Koordinaten
    X = zeros(2,0);
    
    % Abstand zu Grenzen in Längen-/Breitengraden
    br_lat = 0.008;
    br_lon = 0.012;
    bounds = [lat lon lat lon];
    
    step = 1;
    
    node_id_prev = -1;
    coord_prev = [0;0];
    
    api_requests = 0;
    
    fig = figure;
    ax = axes('Parent', fig);
    hold(ax, 'on');
    
    while t < t_end && visible
        % prüfe ob wir uns zu nah an der Grenze der verfügbaren Daten befinden
        if boundaryDistance(coord, bounds) < 0.0005
            %
            % TODO
            % schaue ob brauchbare Kartendaten schon existieren
            %
            bounds = [lat-br_lat lon-br_lon lat+br_lat lon+br_lon];
            api_name = sprintf(...
                '%s/api/interpreter?data=(way["highway"](%f,%f,%f,%f);>;);out;', ...
                'http://overpass-api.de', bounds);
            
            tic; api_requests = api_requests + 1;
            remote_xml = webread(api_name);
            time = toc;
            
            fprintf('API query %d completed in %f seconds.\n', ...
                api_requests, time);
            
            indices = strfind(remote_xml, '<node');
            index = indices(1);

            % xml-Daten müssen manipuliert werden, um vom Parser akzeptiert zu
            % werden
            remote_xml = sprintf(...
                '%s<bounds minlat="%f" minlon="%f" maxlat="%f" maxlon="%f"/>\n  %s', ...
                remote_xml(1:index-1), bounds, remote_xml(index:end));

            %filename = '../../OSMmatlab/map.osm';
            filename = sprintf('maps/map-%f_%f_%f_%f.osm', bounds);
            fid = fopen(filename, 'wt');
            fprintf(fid, '%s', remote_xml);
            fclose(fid);
            
            tic;
            [parsed_osm, ~] = parse_openstreetmap(filename);
            time = toc;
            fprintf(' * Parsed data in %f seconds.\n', time);

            tic;
            % Eigene Function für Adjazenzmatrix
            adj_matrix = adjacencyMatrix(parsed_osm);
            % Symmetrisch machen -> ungerichteter Graph
            dg = or(adj_matrix, adj_matrix.');
            time = toc;
            fprintf(' * Created adjacency matrix in %f seconds.\n', time);
            
            % muss Index neu bestimmen, da sich zugrundeliegende Daten verändert
            % haben
            node_id = findNearestVec(coord, parsed_osm.node.xy);
            node_id_prev = findNearestVec(coord_prev, parsed_osm.node.xy);
            
            if step == 1
                % im ersten Schritt müssen Daten initialisiert werden
                p = osmnode2vec(node_id);
                coord = parsed_osm.node.xy(:,node_id);
                lon = coord(1); lat = coord(2);

                X(:,step) = coord;
            end
            
            plot_streets(ax, parsed_osm);
            
            % Geladenes Straßennetz plotten
            
        end
        
        % Indizes aller adjazenten Knoten
        neighbor_ids = find(dg(:, node_id));
        
        num_neighbors = size(neighbor_ids, 1);
        
        [richtung_optimal, visible] = ...
            earth_path(p, t, delta_t, speed, earth_radius);
        
        richtung_optimal = (richtung_optimal - p)/norm(richtung_optimal-p);
        
        R_neighbor = zeros(3, num_neighbors);
        SP_neighbor = zeros(1, num_neighbors);
        
        for i = 1:num_neighbors
            % bestimme 3d-Position und normalisierte Gang-Richtung für jeden
            % adjazenten Knoten
            R_neighbor(:, i) = osmnode2vec(neighbor_ids(i));
            
            norm_neighbor = norm(R_neighbor(:,i) - p);
            if norm_neighbor == 0
                r_neighbor = zeros(3,1);
            else
                r_neighbor = (R_neighbor(:,i) - p)/norm_neighbor;
            end
            
            SP_neighbor(i) = dot(richtung_optimal, r_neighbor);
        end
        
        [max_colinear, max_index] = max(SP_neighbor);
        
        % Nächstbeste Straße sollte nicht von Sonne weg führen
        if max_colinear > 0
            node_id_prev = node_id;
            node_id = neighbor_ids(max_index);
            
            distance = norm(R_neighbor(:,max_index) - p);
            p = R_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_id);
            lon = coord(1); lat = coord(2);
            
            step = step + 1;
            X(:,step) = coord;
            
            t = t + distance/speed;
        elseif num_neighbors == 2
            node_id_new = neighbor_ids(neighbor_ids ~= node_id_prev);
            node_id_prev = node_id;
            node_id = node_id_new;
            
            distance = norm(R_neighbor(:,max_index) - p);
            p = R_neighbor(:,max_index);
            coord_prev = coord;
            coord = parsed_osm.node.xy(:,node_id);
            lon = coord(1); lat = coord(2);
            
            step = step + 1;
            X(:,step) = coord;
            
            t = t + distance/speed;
        else
            t = t + delta_t;
        end
    end
    
    plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 2);
    hold(ax, 'off');
    
    function d = boundaryDistance(c, bnd)
        if all(c' < bnd([2 1])) || all(c' > bnd([4 3]))
            d = 0;
        else
            d = min(abs(bnd([2 1 4 3]) - repmat(c', 1, 2)));
        end
    end

    function pt = osmnode2vec(idx)
        pt = lonlat2vec(parsed_osm.node.xy(1, idx), ...
            parsed_osm.node.xy(2, idx), earth_radius);
    end
end