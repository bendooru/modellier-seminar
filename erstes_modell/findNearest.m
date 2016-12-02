function idx = findNearest(a, v)
    % Index des Elements mit geringestem Abstand zum gesuchten Element
    v_dist = abs(v - a);
    [~, idx] = min(v_dist);
end