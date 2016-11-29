function X = earth_path(lon, lat, t, delta_t, v, steps)
    X = zeros(3,steps);
    
    earth_rad = 6371000; % Meter
    
    p_0 = zeros(3,1);
    
    [p_0(1), p_0(2), p_0(3)] = sph2cart(lon, lat, earth_rad);
    
    X(:,1) = p_0;
    
    for i=2:steps
        p_prev = X(:, i-1);
        
        p_normal = p_prev ./ norm(p_prev);
        
        sonPos = sonnen_pos(t) - p_prev;
        
        % Projektion?
        sonne_elev = vector_angle(p_prev, sonPos);
        
        if 0 <= sonne_elev && sonne_elev <= pi/2
            richtung = sonPos - dot(sonPos, p_normal).*p_normal;
            if norm(richtung) == 0
                r_normal = 0;
            else
                r_normal = richtung ./ norm(richtung);
            end

            p = p_prev + v*delta_t*r_normal;
            p = (earth_rad/norm(p)) .* p;
        else
            p = p_prev;
        end
        
        X(:, i) = p;
        t = t + delta_t;
    end
    
    function gamma = vector_angle(v1, v2)
        gamma = atan2(norm(cross(v1, v2)), dot(v1, v2));
    end
end