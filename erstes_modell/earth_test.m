figure;
[X, Y, Z] = sphere(110);
earth_rad = 6370999;

surf(earth_rad.*X, earth_rad.*Y, earth_rad.*Z);
hold on;

% in Breitengraden
lon = deg2rad(230); % ←→
lat = deg2rad(0); % ↑↓

T = earth_path(lon, lat, 172*1440, 2, 90, 10000);

plot3(T(1,:), T(2,:), T(3, :), '-r', 'Linewidth', 3);
plot3(T(1, 1), T(2, 1), T(3, 1), '*b', 'Linewidth', 3); 
hold off;