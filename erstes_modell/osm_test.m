
% % Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;

lat = 49.439343; lon = 7.733482;

% % Tokio: rechnet lange!
% lon = 139.774444;
% lat =  35.683889;

% % TU KL
% lon =  7.753056;
% lat = 49.423889;

% lon =  7.311105;
% lat = 49.712424;

% lon = 13; lat = 48;

% % Sydney
% lon = 135.7;
% lat = 35;

delta_t = 1;

fitness.walkpause = [180 30 100 5 200 27 30 5];
fitness.f = { @(t) 20*exp(-t) + 65 };

% Format: tt, mm Tag, Monat
tag = day(21, 6);

[X, ax, D, T] = follow_osm(lon, lat, delta_t, tag, fitness, 'TimePlot');