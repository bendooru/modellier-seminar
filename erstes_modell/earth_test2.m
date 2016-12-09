lon = 10;
lat = 46.5;

speed = 89;
delta_t = 0.5;
tag = 180;

[~, E] = earth_follow_elev(lon, lat, speed, delta_t, tag);