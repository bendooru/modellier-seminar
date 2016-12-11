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
        
        idx_prev = node_ids == nodeset(1);
        
        for i = 1:size(nodeset, 2)
            idx = node_ids == nodeset(1,i);
            % Matrix bereits an dieser Stelle symmetrisch machen
            adjMat(idx_prev, idx) = 1;
            adjMat(idx, idx_prev) = 1;
            
            idx_prev = idx;
        end
    end
    
    for i = 1:size(node_ids, 2)
        adjMat(i,i) = 0;
    end
end