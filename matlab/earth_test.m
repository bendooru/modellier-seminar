figure;
% [X, Y, Z] = sphere(110);
earth_rad = 6371000;
earth_rad_klein = earth_rad - 1;

%surf(earth_rad_klein.*X, earth_rad_klein.*Y, earth_rad_klein.*Z);
hold on;

% in Breitengraden
lon = 180 + 49; % ←→
lat = 7; % ↑↓

steps = 5000;

t_0 = 172 * 1440;
delta_t = 0.5;

p_0 =lonlat2vec(lon, lat, earth_rad);

T = zeros(3, steps);
t_0 = sonnenaufgang(p_0, t_0);
for i = 1:steps
    T(:, i) = p_0;
    p_0 = earth_path(p_0, t_0, delta_t, 90, earth_rad);
    t_0 = t_0 + delta_t;
end

T = T./earth_rad;

earthmap; hold on;
plot3(T(1,:), T(2,:), T(3, :), '-r', 'Linewidth', 3); %
plot3(T(1,1), T(2,1), T(3, 1), '.b', 'Linewidth', 3); % Startpunkt
hold off;

% Koordinatenplot
S = zeros(2, size(T, 2));
[S(1,:), S(2,:), ~] = cart2sph(T(1,:), T(2,:), T(3,:));
S = rad2deg(S);
figure;
plot(S(1, :), S(2, :));