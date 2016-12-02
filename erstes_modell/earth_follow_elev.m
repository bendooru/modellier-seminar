function S = earth_follow_elev(lon, lat, speed, delta_t, tag)
    earth_rad = 6371000;
    p_0 = zeros(3,1);
    
    % Berechnung ausgehend von Breiten-/Längengraden
    [p_0(1), p_0(2), p_0(3)] = sph2cart(deg2rad(lon), deg2rad(lat), earth_rad);
    [t_0, visible] = sonnenaufgang(p_0, tag);
    t = t_0;
    p = p_0;
    
    % A priori umschließendes Koordinatenrechteck, um Höhendaten bestimmen zu
    % können
    LAT = [round(lat-0.5), round(lat+0.5)];
    LON = [round(lon-0.5), round(lon+0.5)];
    
    R = readhgt(LAT, LON);
    
    maxsteps = round(1440/delta_t);
    X = zeros(3, maxsteps);
    S = zeros(2, maxsteps);
    E = zeros(1, maxsteps);
    i = 1;
    
    % erster Schritt außerhalb der Schleife
    X(:,i) = p;
    [S(1,i), S(2, i), ~] = cart2sph(X(1,i), X(2,i), X(3,i));
    S(:,i) = rad2deg(S(:,i));
    E(i) = get_elevation(S(1,i), S(2,i));
    
    % brich ab, sobald Sonne nicht weiter sichtbar oder 24 Stunden vergangen
    while t < t_0 + 1440 && visible
        i = i+1;
        [p, visible] = earth_path(p, t, delta_t, speed, earth_rad);
        
        X(:, i) = p;
        [S(1,i), S(2, i), ~] = cart2sph(X(1,i), X(2,i), X(3,i));
        S(:,i) = rad2deg(S(:,i));
        E(i) = get_elevation(S(1,i), S(2,i));
        
        % Zeit, um Höhenunterschied zu überbrücken
        slope_delta = sqrt(((E(i)-E(i-1))/speed)^2 + delta_t^2);
        
        % (3 ist elativ zufällig gewählt)
        % falss slope_delta zu groß, tue nichts da die Steigung nicht
        % überbrückbar ist
        if slope_delta/delta_t > 3
            % alles zurücksetzen
            X(:,i) = X(:,i-1);
            S(:,i) = S(:,i-1);
            E(i) = E(i-1);
            t = t + delta_t;
        else
            % Annahme: Abstieg kann in kürzerer Zeit bewerkstelligt werden
            if E(i) < E(i-1)
                t = t + delta_t;
            else
                t = t + slope_delta;
            end
        end
    end
    
    % entferne überschüssige 0-Elemente
    S = S(:,1:i);
    
    AREA = zeros(1,4);
    % verkleinere umschließendes Rechteck
    AREA([3 1]) = min(S,[],2) - 0.05;
    AREA([4 2]) = max(S,[],2) + 0.05;
    
    readhgt(AREA);
    hold on;
    plot(S(1,:), S(2,:), '-r', 'LineWidth', 2);
    hold off;
    
    % finde zunächst nächstgelegenstes Element in in Koordinatenvektoren,
    % anschließend gib Höhenwert an diesen Indizes aus
    function elev = get_elevation(lon, lat)
        idxlon = findNearest(lon, R.lon);
        idxlat = findNearest(lat, R.lat);
        elev = R.z(idxlat, idxlon);
    end
end