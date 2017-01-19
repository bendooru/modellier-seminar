function plot_streets(ax, parsed_osm)
    [~, node, way, ~] = assign_from_parsed(parsed_osm);
    
    ways_num = size(way.id, 2);
    ways_node_sets = way.nd;
    node_ids = node.id;
    
    % Iteriere durch jeden Way und plotte die Strecke
    for currway = 1:ways_num
        nodeset = ways_node_sets{1, currway};
        nodeids = zeros(size(nodeset));
        
        % finde index in xy zu Node-ID
        for i = 1:size(nodeids,2)
            nodeids(1,i) = find(nodeset(1,i) == node_ids);
        end
        
        XY = node.xy(:, nodeids);
        plot(ax, XY(1, :), XY(2, :), '-b');
    end
end