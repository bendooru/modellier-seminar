% Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;
% lat = 49.439343; lon = 7.733482;
% Tokio: rechnet lange!
% coord = [139.775, 35.68];
% % TU KL
% coord = [7.753056, 49.423889];
% coord = [7.311105, 49.712424];
% KW
% coord = [7.240602, 49.752821];
% Sydney
% coord = [135.7, 35];
% Irgendwo anders in Japan
coord = [132.9994, 33.3704];

fitness.walkpause = [900; 0];
fitness.f = { @(t) 90 };

%[X, D, T, ax] = follow_osm(lon, lat, delta_t, tag, fitness, 'Animate', 'Elevation');
ax = osm_gui(21, 6, fitness, 'Animate', 'Coord', coord);