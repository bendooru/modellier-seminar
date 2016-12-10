
% % Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;

% Tokio: rechnet lange!
lon = 139.774444;
lat =  35.683889;

% % TU KL
% lon =  7.753056;
% lat = 49.423889;

% lon =  7.735440;
% lat = 49.43914;

delta_t = 1;
speed = 90; % [m/min]

% fehlt: day.m integrieren
tag = 172;

X = follow_osm(lon, lat, delta_t, speed, tag);