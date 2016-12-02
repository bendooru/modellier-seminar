function idx = findNearest(a, v)
    v_dist = abs(v - a);
    [~, idx] = min(v_dist);
end