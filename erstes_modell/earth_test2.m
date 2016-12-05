lon = 7.21;
lat = 48.99;

speed = 95;
delta_t = 0.5;
tag = 180;

[~, E] = earth_follow_elev(lon, lat, speed, delta_t, tag);

%plot(S(1,:), S(2,:));