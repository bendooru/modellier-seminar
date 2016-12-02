function [p, visible] = earth_path(p_0, t, delta_t, v, radius)
    p_normal = p_0 ./ norm(p_0);

    sonPos = sonnen_pos(t) - p_0;
    sonne_elev = vector_angle(p_0, sonPos);
    
    % Winkel liegt in [0, pi/2], wenn Sonne über Horizont sichtbar
    visible = 0 <= sonne_elev && sonne_elev <= pi/2;

    if visible
        % Projektion auf durch Normalenvektor aufgespannte Ebene
        richtung = sonPos - dot(sonPos, p_normal).*p_normal;
        % für Spezialfälle,verhindert NaN-Einträge
        if norm(richtung) == 0
            r_normal = 0;
        else
            r_normal = richtung ./ norm(richtung);
        end

        % lineare Bewegung in Richtung der Projektion
        p = p_0 + v*delta_t*r_normal;
        % Normierung auf Kugeloberfläche
        p = (radius/norm(p)) .* p;
    else
        % tue nichts, falls Sonne nicht sichtbar
        p = p_0;
    end
end