function idx = findNearest(a, v)
    % Index des Elements mit geringestem Abstand zum gesuchten Element
    % skalarer Fall!
    [~, idx] = min(abs(v-a));
end