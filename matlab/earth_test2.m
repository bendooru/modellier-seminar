% lon = 7.768889;
% lat = 49.444722;

% lon = 138.774444;
% lat =  36.684989;

lon = 10; lat = 45.5;

speed = 90;
delta_t = 2.5;
tag = 172;

% füge 1 als 6. Argument hinzu, um für konstante Geschw. zu plotten
[S, E, T] = earth_follow_elev(lon, lat, speed, delta_t, tag);
[SC, EC] = earth_follow_elev(lon, lat, speed, delta_t, tag, 1);

dist = norm(lonlat2vec(S(1,end), S(2, end), 6371000) - ...
    lonlat2vec(SC(1, end), SC(2, end), 6371000));

fprintf('Enpunkte haben Distanz %f m\n', dist);