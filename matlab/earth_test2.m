lon = 7.768889;
lat = 49.444722;

% lon = 138.774444;
% lat =  36.684989;

% lon=7.240602; lat=49.752821;

% lon = 10; lat = 45.5;

speed = 90;
delta_t = 1;
tag = 172;

% füge 1 als 6. Argument hinzu, um für konstante Geschw. zu plotten
% setenv('MATLAB_SUNPOSITION_FUN', '');
%[S, E, T] = earth_follow_elev(lon, lat, speed, delta_t, tag);
% setenv('MATLAB_SUNPOSITION_FUN', 'exact');
SC = earth_follow_elev(lon, lat, speed, delta_t, tag, 'ConstantSpeed', 'Plot');

hold on;
plot(S(1, :), S(2, :), '-b', 'LineWidth', 2);
hold off;

dist = norm(lonlat2vec(S(1,end), S(2, end), 6371000) - ...
    lonlat2vec(SC(1, end), SC(2, end), 6371000));

% f=figure; hold on;
% plot(S(1, :), S(2, :));
% plot(SC(1, :), SC(2, :));
% legend('mit Höhendaten', 'ohne Höhendaten');
% hold off;

fprintf('Enpunkte haben Distanz %f m\n', dist);