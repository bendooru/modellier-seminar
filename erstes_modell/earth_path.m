function p = earth_path(p_0, t, delta_t, v, radius)
    p_normal = p_0 ./ norm(p_0);

    sonPos = sonnen_pos(t) - p_0;

    % Projektion?
    sonne_elev = vector_angle(p_0, sonPos);

    if 0 <= sonne_elev && sonne_elev <= pi/2
        richtung = sonPos - dot(sonPos, p_normal).*p_normal;
        if norm(richtung) == 0
            r_normal = 0;
        else
            r_normal = richtung ./ norm(richtung);
        end

        p = p_0 + v*delta_t*r_normal;
        p = (radius/norm(p)) .* p;
    else
        p = p_0;
    end
    
    function gamma = vector_angle(v1, v2)
        gamma = atan2(norm(cross(v1, v2)), dot(v1, v2));
    end
end