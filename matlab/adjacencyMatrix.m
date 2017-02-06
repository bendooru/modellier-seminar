function adjMat = adjacencyMatrix(parsed_osm)
    [~, node, way, ~] = assign_from_parsed(parsed_osm);
    
    ways_num = size(way.id, 2);
    ways_node_sets = way.nd;
    node_ids = node.id;
    
    adjMat = sparse(size(node_ids, 2));
    
    for currway = 1:ways_num
        nodeset = ways_node_sets{1, currway};
        numnodes = size(nodeset, 2);
        if numnodes < 2
            continue;
        end
        
        idx_prev = find(node_ids == nodeset(1,1));
        
        for i = 2:size(nodeset, 2)
            idx = find(node_ids == nodeset(1,i));
            % Matrix bereits an dieser Stelle symmetrisch machen
            if idx_prev ~= idx
                adjMat(idx_prev, idx) = 1;
                adjMat(idx, idx_prev) = 1;
            end
            
            idx_prev = idx;
        end
    end
end