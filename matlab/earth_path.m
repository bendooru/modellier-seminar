function [visible, p] = earth_path(p_0, t, delta_t, v, radius)
    % EARTH_PATH Berechnet nächste Position ausgehend von Position und Zeit.
    %   Aufruf: [visible, p] = earth_path(p_0, t, delta_t, v, radius) mit
    %   p_0     Ausgangsposition
    %   t       Zeitpunkt
    %   delta_t Schrittdauer
    %   v       Geschwindigkeit
    %   radius  Radius der Erde
    %   visible Sichtbarkeit der Sonne zum Zeitpunkt t
    %   p       nächste Position
    %
    % Funktionsweise siehe Ausarbeitung bzw. Folien
    
    % Verwende Umgebungsvariablen, um Funktionsweise zu wählen
    if ~strcmpi(getenv('MATLAB_SUNPOSITION_FUN'), 'exact')
        p_normal = p_0 ./ norm(p_0);

        % sonne_pos kann theoretisch auch in diese Funktion integriert werden
        sonPos = sonnen_pos(t) - p_0;
        sonne_elev = vector_angle(p_0, sonPos);

        % Winkel liegt in [0, pi/2], wenn Sonne über Horizont sichtbar
        visible = 0 <= sonne_elev && sonne_elev <= pi/2;

        % falls p nicht als Ausgabe gebraucht wird, spare Rechenzeit
        if nargout > 1
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
    else
        [lon, lat, ~] = cart2sph(p_0(1), p_0(2), p_0(3));
        LON = rad2deg(lon);
        LAT = rad2deg(lat);
        timeS = datetime('01-Jan-2017 00:00:00') + minutes(t);

        [az, el] = SolarAzEl(timeS, LAT, LON, 100);

        % Sonnenhöhenwinkel
        visible = el >= 0;

        if nargout > 1
            e = rotz(lon)*roty(lat)*rotx(-deg2rad(az))*[0;0;1];

            p = p_0 + (delta_t*v).*e;
            p = (radius/norm(p)).*p;
        end
    end
    
    function R = rotx(alpha)
        R = [1, 0, 0; 0, cos(alpha), -sin(alpha); 0, sin(alpha), cos(alpha)];
    end

    function R = roty(alpha)
        R = [cos(alpha), 0, -sin(alpha); 0, 1, 0; sin(alpha), 0, cos(alpha)];
    end

    function R = rotz(alpha)
        R = [cos(alpha), -sin(alpha), 0; sin(alpha), cos(alpha), 0; 0, 0, 1];
    end
end