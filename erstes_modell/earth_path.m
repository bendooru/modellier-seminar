function [p, visible] = earth_path(p_0, t, delta_t, v, radius)
    p_normal = p_0 ./ norm(p_0);

    sonPos = sonnen_pos(t) - p_0;
    sonne_elev = vector_angle(p_0, sonPos);
    
    visible = 0 <= sonne_elev && sonne_elev <= pi/2;

    if visible
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
end