lon = 7.03;
lat = 31.99;

speed = 90;
delta_t = 0.5;
tag = 180;

[~, E] = earth_follow_elev(lon, lat, speed, delta_t, tag);