% Kaiserslautern irgendwo
% lon =  7.768889;
% lat = 49.444722;
% lat = 49.439343; lon = 7.733482;
% Tokio: rechnet lange!
% coord = [139.775, 35.68];
% % TU KL
coord = [7.753056, 49.423889];
% coord = [7.311105, 49.712424];
% KW
% coord = [7.240602, 49.752821];
% Sydney
% coord = [135.7, 35];
% Irgendwo anders in Japan
% coord = [132.9994, 33.3704];
% 

% coord = [28.929557, 69.051942];
fitness.walkpause = [180; 25];
fitness.f = { @(t) 90 };

tag = 3;
monat = 2;

exmstr = 'KW';
str = sprintf('%s [%.6f, %.6f] (%d/%d)\n', exmstr, coord, tag, monat);

% [X, ax] = follow_osm_free(coord(1), coord(2), 1.5, 90, 172);
% ax = osm_gui(21, 6, fitness, 'Animate', 'Coord', [7 49]);
[X, ~, T] = follow_osm(coord(1), coord(2), 1, day(tag, monat), fitness, 'NoElevation');

%save('beispiele/ex04etwas.mat', 'str', 'coord', 'fitness', 'tag', 'monat', 'X', 'T');