lon = 7.768889;
lat = 49.444722;

% lon = 139.774444;
% lat =  35.683889;

speed = 90;
delta_t = 1;
tag = 172;

% füge 1 als 6. Argument hinzu, um für konstante Geschw. zu plotten
[S, E] = earth_follow_elev(lon, lat, speed, delta_t, tag);