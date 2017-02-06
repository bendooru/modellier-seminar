function tileBackground(xrange, yrange, ax)
    ax.XLim = xrange; ax.YLim = yrange;
    %drawnow;
    maxLat = rad2deg(atan(sinh(pi)));

    tiledir = 'tiles';
    if ~isdir(tiledir)
        mkdir(tiledir);
    end

    % Errechne angemessenes Zoom-Level aus Plot-Größe
    oldunits = ax.Units;
    ax.Units = 'pixels';
    pixelheight = ax.Position(4);
    ax.Units = oldunits;

    zlevel_ur = log2((pixelheight * maxLat)/range(yrange)) - 7;
    zlevel = arrBounds(floor(zlevel_ur), 0, 16);

    % Vergrößere Nachträglich Plotbereich, um Tile pixelgetreu darzustellen
    meanx = mean(xrange);
    xrange = meanx + 2^(zlevel_ur-zlevel).*(xrange-meanx);
    meany = mean(yrange);
    yrange = meany + 2^(zlevel_ur-zlevel).*(yrange-meany);
    ax.XLim = xrange; ax.YLim = yrange;

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
                      'YData', cornerLat((yy:yy+1)-ymin+1), ...
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
    
    close(wb);

    % Berechnung der Tile-Daten (sie OSM-Wiki)
    function [x, y] = coord2tile(LON, LAT, Zoom)
        N = 2^Zoom;
        
        % wegen Rundungsfehlern am Rand nach Berechnung sicherstellen, dass Werte in
        % richtigem Intervall
        x = floor((LON+180)./360 .* N);
        x = arrBounds(x, 0, N-1);
        
        y = floor((1-asinh(tan(deg2rad(arrBounds(LAT, -maxLat, maxLat))))./pi).*(N/2));
        y = arrBounds(y, 0, N-1);
    end

    function [LON, LAT] = tile2coordNW(X, Y, Zoom)
        N = 2^Zoom;
        LON = (X./N) .* 360 - 180;
        LAT = rad2deg(atan(sinh(pi - (2*pi).*(Y./N))));
    end

    function tileimg = gettile(x, y, zlevel)
        tilename = fullfile(tiledir, sprintf('%d-%d-%d.png', zlevel, x, y));
        
        if ~exist(tilename, 'file')
            subdom = 'abc';
            websave(tilename, sprintf(...
                'http://%c.tile.openstreetmap.org/%d/%d/%d.png', ...
                subdom(randi(3, 1)), zlevel, x, y));
            fprintf('F');
        else
            fprintf('l');
        end
        
        % für Benutzung von image anpassen
        [tileimg, tmap] = imread(tilename);
        if ~isempty(tmap)
            tileimg = ind2rgb(tileimg, tmap);
        end
    end
    
    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end
end