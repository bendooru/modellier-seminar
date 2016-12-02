lon = 7.02;
lat = 48.8;

speed = 90;
delta_t = 0.5;
tag = 300;

S = earth_follow_elev(lon, lat, speed, delta_t, tag);

%plot(S(1,:), S(2,:));