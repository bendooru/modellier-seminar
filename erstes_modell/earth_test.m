figure;
[X, Y, Z] = sphere(110);
earth_rad = 6371000;
earth_rad_klein = earth_rad - 1;

surf(earth_rad_klein.*X, earth_rad_klein.*Y, earth_rad_klein.*Z);
hold on;

% in Breitengraden
lon = deg2rad(230); % ←→
lat = deg2rad(0); % ↑↓

T = earth_path(lon, lat, 172*1440, 2, 90, 10000, earth_rad);

plot3(T(1,:), T(2,:), T(3, :), '-r', 'Linewidth', 3);
hold off;