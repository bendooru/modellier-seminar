
% % Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;

% lat = 49.439343; lon = 7.733482;

% % Tokio: rechnet lange!
% lon = 139.775;
% lat =  35.68;

% TU KL
lon =  7.753056;
lat = 49.423889;

% lon =  7.311105;
% lat = 49.712424;

% lon = 7.240602; lat = 49.752821;

% lat = 45; lon = 10;

% % Sydney
% lon = 135.7;
% lat = 35;

delta_t = 1;

fitness.walkpause = [900 0];
fitness.f = { @(t) 90 };

%[X, D, T, ax] = follow_osm(lon, lat, delta_t, tag, fitness, 'Animate', 'Elevation');
ax = osm_gui(21, 12, fitness, 'Animate');