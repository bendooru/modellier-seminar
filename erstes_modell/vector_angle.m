function gamma = vector_angle(v1, v2)
    % Herleitung siehe Folien
    gamma = atan2(norm(cross(v1, v2)), dot(v1, v2));
end
