function tileBackground(xrange, yrange, ax)
    % TILEBACKGROUND Plottet OpenStreetMap-Kacheln innerhalb der Koordinatenintervalle.
    %   Aufruf: tileBackground(xrange, yrange, ax) mit Argumenten:
    %   xrange  Intervallgrenzen der zu plottenden Längengrade,
    %   yrange  Intervallgrenzen der zu plottenden Breitengrade,
    %   ax      Axis in die geplottet werden soll.
    %
    %   Es wird dabei aus der Größe des Plotbereichs in Pixeln das adäquate Zoom-Level
    %   errechnet und anschließend die benötigten Kacheln ggf. heruntergeladen und in ax
    %   geplottet.
    %
    %   Ausgabe auf der Kommandozeile während 
    
    ax.XLim = xrange; ax.YLim = fromMercator(yrange);
    maxLat = pi;

    % Ordner, in dem Kacheldateien gespeichert werden sollen
    tiledir = fullfile(fileparts(mfilename('fullpath')),'tiles');
    if ~isdir(tiledir)
        mkdir(tiledir);
    end

    % Errechne angemessenes Zoom-Level aus Plot-Größe
    oldunits = ax.Units;
    ax.Units = 'pixels';
    pixelwidth  = ax.Position(3);
    pixelheight = ax.Position(4);
    ax.Units = oldunits;

    % wählere kleineres ZoomLevel berechnet nach x- und y-Längen
    % Rechung ist im Grunde Dreisatz mit jeweils Höhe und Breite, nimm Minimum, da Matlab
    % die Dimensionen des Plots größer als dargestellt angibt
    zlevel_ur = min(log2((pixelheight * maxLat)/range(fromMercator(yrange))) - 7, ...
        log2((pixelwidth * 180)/range(xrange)) - 7);
    zlevel = arrBounds(floor(zlevel_ur), 0, 16);

    % Vergrößere Nachträglich Plotbereich, um Tile pixelgetreu darzustellen
    % wir zoomen niemals hinein, da sonst Informationen außerhalb des Plotbereichs landen
    % könnten
    meanx = mean(xrange);
    xrange = meanx + 2^(zlevel_ur-zlevel).*(xrange-meanx);
    meany = mean(yrange);
    yrange = arrBounds(meany + 2^(zlevel_ur-zlevel).*(yrange-meany), ...
        toMercator(-pi), toMercator(pi));
    ax.XLim = xrange; ax.YLim = fromMercator(yrange);

    [xmax, ymax] = coord2tile(xrange(2), yrange(1), zlevel);
    [xmin, ymin] = coord2tile(xrange(1), yrange(2), zlevel);

    [cornerLon, cornerLat] = tile2coordNW(xmin:xmax+1, ymin:ymax+1, zlevel);
    
    wb = waitbar(0, 'Aktualisiere Karte ...');
    karten = 0;
    karten_max = numel(xmin:xmax) * numel(ymin:ymax);
    
    % Fange (Netzwerk-)Fehler ab
    try
        fprintf('Tiles: ');
        for xx=xmin:xmax
            for yy=ymin:ymax
                TILE = gettile(xx, yy, zlevel);

                image('XData', cornerLon((xx:xx+1)-xmin+1), ...
                      'YData', fromMercator(cornerLat((yy:yy+1)-ymin+1)), ...
                      'CData', TILE, 'Parent', ax);

                karten = karten + 1;
                waitbar(karten/karten_max, wb);
            end
        end
        fprintf('\n');
    catch ME
        errordlg(getReport(ME, 'extended', 'hyperlinks', 'off'), 'Fehler');
        close(wb);
        rethrow(ME)
    end
    
    set(ax, 'YTickLabel', cellstr(num2str(toMercator(get(ax, 'YTick')'))));
    
    close(wb);

    % Berechnung der Tile-Daten (sie OSM-Wiki)
    function [x, y] = coord2tile(LON, LAT, Zoom)
        N = 2^Zoom;
        
        % wegen Rundungsfehlern am Rand nach Berechnung sicherstellen, dass Werte in
        % richtigem Intervall
        x = floor((LON+180)./360 .* N);
        x = arrBounds(x, 0, N-1);
        
        y = floor((1-arrBounds(asinh(tan(deg2rad(LAT))), -maxLat, maxLat)./pi).*(N/2));
        y = arrBounds(y, 0, N-1);
    end

    function [LON, LAT] = tile2coordNW(X, Y, Zoom)
        N = 2^Zoom;
        LON = (X./N) .* 360 - 180;
        LAT = rad2deg(atan(sinh(pi - (2*pi).*(Y./N))));
    end

    function tileimg = gettile(x, y, zlevel, tries)
        % Bei Wiederversuch ist tries gesetzt
        if nargin < 4
            tries = 0;
        end
        
        tilename = fullfile(tiledir, sprintf('%d-%d-%d.png', zlevel, x, y));
        
        if ~exist(tilename, 'file')
            subdom = 'abc';
            websave(tilename, sprintf(...
                'http://%c.tile.openstreetmap.org/%d/%d/%d.png', ...
                subdom(randi(3, 1)), zlevel, x, y));
            % Datei musste heruntergeladen werden (Fetched)
            fprintf('F');
        else
            % Datei lokal gefunden
            fprintf('l');
        end
        
        % für Benutzung von image anpassen
        try
            [tileimg, tmap] = imread(tilename);
            if ~isempty(tmap)
                tileimg = ind2rgb(tileimg, tmap);
            end
        catch ME
            if tries > 10
                % Nach 10 Verbindungsversuchen gib einfach den Fehler aus
                rethrow(ME);
            end
            fprintf('e');
            delete(tilename);
            % sonst rufe die Funktion einfach erneut auf
            tileimg = gettile(x, y, zlevel, tries+1);
        end
    end
    
    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end

    % Hin- und Rücktrannsformation für Mercatorprojektion
    function LAT = toMercator(Y)
        LAT = rad2deg(atan(sinh(Y)));
    end

    function Y = fromMercator(LAT)
        Y = asinh(tan(deg2rad(LAT)));
    end
end