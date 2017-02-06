function [S, E, T] = earth_follow_elev(lon, lat, speed, delta_t, tag, cs)
    earth_rad = 6371000;
    
    % einfacher Schalter, um Geschwindigkeit konstant zu machen
    variable_speed = true;
    if (nargin == 6)
        if cs == 1
            variable_speed = false;
        end
    end
    
    % Berechnung ausgehend von Breiten-/Längengraden
    p_0 = lonlat2vec(lon, lat, earth_rad);
    [t_0, visible] = sonnenaufgang(p_0, tag);
    t = t_0;
    p = p_0;
    
    % A priori umschließendes Koordinatenrechteck, um Höhendaten bestimmen zu
    % können
    LAT = [floor(lat-0.5), ceil(lat+0.5)];
    LON = [floor(lon-0.5), ceil(lon+0.5)];
    
    if ~isdir('hgt')
        mkdir('hgt');
    end
    
    % http funktioniert irgendwie nicht mehr
    R = readhgt([LAT, LON], 'interp', 'outdir', 'hgt', ...
        'url', 'https://dds.cr.usgs.gov/srtm/version2_1');
    
    maxsteps = round(1440/delta_t);
    X = zeros(3, maxsteps);
    S = zeros(2, maxsteps);
    V = zeros(1, maxsteps);
    E = zeros(1, maxsteps);
    T = zeros(1, maxsteps);
    i = 1;
    
    % erster Schritt außerhalb der Schleife
    X(:,i) = p;
    [S(1,i), S(2, i), ~] = cart2sph(X(1,i), X(2,i), X(3,i));
    S(:,i) = rad2deg(S(:,i));
    E(i) = get_elevation(S(1,i), S(2,i));
    
    % brich ab, sobald Sonne nicht weiter sichtbar oder 24 Stunden vergangen
    while t < t_0 + 1440 && visible
        i = i+1;
        [visible, p] = earth_path(p, t, delta_t, speed, earth_rad);
        
        X(:, i) = p;
        [S(1,i), S(2, i), ~] = cart2sph(X(1,i), X(2,i), X(3,i));
        S(:,i) = rad2deg(S(:,i));
        E(i) = get_elevation(S(1,i), S(2,i));
        T(i-1) = t;
        
        % Zeit, um Höhenunterschied zu überbrücken
        % siehe Tobler's hiking function
        if variable_speed
            actual_speed = (speed/6) * tobler( (E(i) - E(i-1))/(delta_t*speed) );
        else
            actual_speed = speed;
        end
        
        delta_t_true = delta_t * speed / actual_speed;
        V(i-1) = actual_speed;
        
        % (3 ist elativ zufällig gewählt)
        % falss slope_delta zu groß, tue nichts da die Steigung nicht
        % überbrückbar ist
        if actual_speed < 7
            % alles zurücksetzen
            X(:,i) = X(:,i-1);
            S(:,i) = S(:,i-1);
            E(i) = E(i-1);
            t = t + delta_t;
        else
            t = t + delta_t_true;
        end
    end
    
    % entferne überschüssige 0-Elemente
    S = S(:,1:i);
    E = E(:,1:i);
    T = T(:,1:i-1);
    figure; plot(datetime('01-Jan-2017 00:00:00') +  minutes(T), V(:,1:i-1));
    AREA = zeros(1,4);
    % verkleinere umschließendes Rechteck
    AREA([3 1]) = min(S,[],2) - 0.05;
    AREA([4 2]) = max(S,[],2) + 0.05;
    
    readhgt(AREA, 'outdir', 'hgt', 'url', 'https://dds.cr.usgs.gov/srtm/version2_1');
    hold on;
    plot(S(1,:), S(2,:), '-r', 'LineWidth', 2);
    hold off;
    
    % Toblers Wanderfunktion in km/h
    function v = tobler(slope)
        v = 6 * exp( (-3.5) * abs(slope + 0.05));
    end
    
    % interpoliere Höhe aus 4 umliegenden Punkten
    % verkleinern der Eingabe erhöht Performance von interp2 _immens_
    function elev = get_elevation(lon, lat)
        idxlat = findNearest(lat, R.lat);
        idxlon = findNearest(lon, R.lon);
        rLat = max(1, idxlat-1):min(size(R.lat, 1), idxlat+1);
        rLon = max(1, idxlon-1):min(size(R.lon, 2), idxlon+1);
        elev = interp2(R.lat(rLat), R.lon(rLon), double(R.z(rLat, rLon)'), lat, lon);
    end
end