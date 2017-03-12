% füge nötige Dateien dem Pfad hinzu, installiere Toolbox
% ... hoffentlich

basepath = fileparts(mfilename('fullpath'));

% verwende exemplarisch xml2struct als externe Funktion
if exist('xml2struct_fex28518', 'file') ~= 2
    paths = { 'readhgt', 'solar' };
    osmpaths = fullfile('dependencies', ...
        { 'gaimc', 'hold', 'lat_lon_proportions', 'plotmd', 'xml2struct' });

    allpaths = fullfile(basepath, 'externe_resourcen', [paths, osmpaths]);
    
    addpath(allpaths{:}, '-end');
end

if exist('parse_openstreetmap', 'file') ~= 2
    osmpath = fullfile(basepath, 'externe_resourcen', 'openstreetmap');
    if ~isdir(osmpath)
        zipfile = fullfile(basepath, 'openstreetmap-0.3.zip');
        if exist(zipfile, 'file') == 2
            unzip(zipfile, osmpath)
        end
    end

    if isdir(osmpath)
        addpath(osmpath, '-end')
    else
        warning('openstreetmap-Ordner nicht vorhanden!');
        warning('Platziere openstreetmap-v0.3.zip in diesem Ordner.'); 
    end
end
if exist('uiextras.HBox', 'class') ~= 8
    guipaths = fullfile(basepath, 'guilayout', {'', 'layout', 'layoutdoc'});
    addpath(guipaths{:}, '-end');
end

% Schließlich eigene Funktionen
if exist('SonneGUI', 'file') ~= 2
    addpath(fullfile(basepath, 'matlab'), '-end');
end

clear basepath paths osmpaths allpaths osmpath guipaths;