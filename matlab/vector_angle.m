function gamma = vector_angle(v1, v2)
    % VECTOR_ANGLE Berechnet Winkel zwischen dreidimensionalen Vektoren.
    %   Aufruf: gamma = vector_angle(v1, v2) mit:
    %   v1, v2  Vektoren mit product(size(vi)) == 3
    %   gamma   Winkel zwischen v1 und v2
    %
    %   Funktionsweise siehe Ausarbeitung bzw. Folien
    gamma = atan2(norm(cross(v1, v2)), dot(v1, v2));
end
