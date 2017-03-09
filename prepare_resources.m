% füge nötige Dateien dem Pfad hinzu, installiere Toolbox
% ... hoffentlich

basepath = fileparts(mfilename('fullpath'));

% verwende exemplarisch openstreetmap als externe Funktion
if exist('parse_openstreetmap', 'file') ~= 2
    paths = { 'readhgt', 'solar', 'openstreetmap' };
    osmpaths = fullfile('dependencies', ...
        { 'gaimc', 'hold', 'lat_lon_proportions', 'plotmd', 'xml2struct' });

    allpaths = fullfile(basepath, 'externe_resourcen', [paths, osmpaths]);
    
    addpath(allpaths{:}, '-end');
end

if exist('uiextras.HBox', 'class') ~= 8
    guipaths = fullfile(basepath, 'guilayout', {'', 'layout', 'layoutdoc'});
    addpath(guipaths{:}, '-end');
end

% Schließlich eigene Funktionen
if exist('SonneGUI', 'file') ~= 2
    addpath(fullfile(basepath, 'matlab'), '-end');
end
