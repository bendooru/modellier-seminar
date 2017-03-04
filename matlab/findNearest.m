function idx = findNearest(a, v)
    % FINDNEAREST Index des Elements mit geringestem Abstand zum gesuchten Element
    %   Aufruf: idx = findNearest(a, v) mit
    %   a   zu suchender Skalar
    %   v   Vektor
    %   idx Index mit |v(idx) - a| minimal
    [~, idx] = min(abs(v-a));
end