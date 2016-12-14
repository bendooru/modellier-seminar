
% % Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;

% % Tokio: rechnet lange!
% lon = 139.774444;
% lat =  35.683889;

% TU KL
lon =  7.753056;
lat = 49.423889;

% lon =  7.311105;
% lat = 49.712424;

% lon = 13; lat = 48;

% % Sydney
% lon = 135.7;
% lat = 35;

delta_t = 1;
speed = 90; % [m/min]

% Format: tt, mm Tag, Monat
tag = day(21, 6);

[X, ax] = follow_osm(lon, lat, delta_t, speed, tag);