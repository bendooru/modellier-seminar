function ax = osm_gui(d, m, fitness, varargin)
    % Beispieltext
    
    % figure in die die Karte geplottet wird
    fig = figure;
    maxLat = rad2deg(atan(sinh(pi)));
    ax = axes('Parent', fig);
    daspect(ax, [1, maxLat/180, 1]);
    
    ax.XLim = [-180, 180];
    ax.YLim = [-maxLat, maxLat];
    
    xlabel(ax, 'Longitude (°)');
    ylabel(ax, 'Latidude (°)');
    
    drawnow;

    tiledir = 'tiles';
    if ~isdir(tiledir)
        mkdir(tiledir);
    end
    
    coordStr = strcmpi('Coord', varargin);
    if any(coordStr)
        try
            % Lese Koordinaten aus nächstem Argument
            coord = varargin{find(coordStr, 1)+1};
        catch
            fprintf('Malformed input\n');
            return;
        end
    else
        zoomstep = 1;
        button = 0;
        coord = [0,0];
        
        maxzoom = 15;
        
        widthhv = 180*[-1, 1];
        heighthv = maxLat*[-1, 1];
        
        while zoomstep <= maxzoom && button ~= 3
            ax.Title.String = 'Getting map ...';
            drawnow; 
            % Lösche Inhalt des Plots, um Verlangsumung zu verhindern
            cla(ax);
            
            xRange = arrBounds(coord(1) + widthhv, -180, 180);
            yRange = arrBounds(coord(2) + heighthv, -maxLat, maxLat);
            
            hold(ax, 'on');
            tileBackground(xRange, yRange);
            hold(ax, 'off');
            
            if zoomstep == maxzoom
                ax.Title.String = 'Click to choose Starting Point';
            else
                ax.Title.String = ...
                    'Left click to zoom in; right click to choose Starting Point';
            end
            drawnow;
            
            button = [];
            
            % sorgt dafür, dass nur Maus-Input zählt
            while ~isscalar(button)
                [coord(1), coord(2), button] = ginput(1);
            end
            zoomstep = zoomstep + 1;
            
            % halbiere Breite und Höhe des Zoom-Fensters
            widthhv = widthhv./2;
            heighthv = heighthv./2;
        end
    end
    
    hold(ax, 'on');
    
    tag = day(d, m);
    datum = datestr(datetime('2000-12-31') + tag, 'mmmm dd');
    title(ax, datum);
    drawnow;
    
    wbh = waitbar(0, 'Calculating route ...');
    
    [X, D, T] = follow_osm(coord(1), coord(2), 1, tag, fitness, wbh);
    
    close(wbh);
    
    % OSM-Tiles einfügen
    fprintf('Plotting background tiles:\n');
    
    cla(ax);
    % Extrema
    xyRange = minmax(X) + [-0.005, 0.005; -0.005, 0.005];
    
    tileBackground(xyRange(1, :), xyRange(2, :));
    
    % rufe follow_osm mit dem Argument 'Animate' am Ende auf, um die entstehende Route
    % animiert zu plotten
    fprintf('Plotting route ... ');
    if any(strcmpi('Animate', varargin))
        h = animatedline('Color', 'r', 'LineWidth', 1.5);
        p = plot(ax, X(1, 1), X(2, 1),'o','MarkerFaceColor','red');
        
        for i = 1:size(X, 2)
            addpoints(h, X(1, i), X(2, i));
            p.XData = X(1, i);
            p.YData = X(2, i);
            ax.Title.String = sprintf('%s [%5.1f min]', datum, T(1, i) - T(1, 1));
            drawnow;
        end
    else
        % normaler, sofortiger Plot
        plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 1.5);
    end
    
    hold(ax, 'off');
    fprintf('done.\n');
    
    % Plotte zurückgelegte Distanz über Zeit (nur wenn 'TimePlot' als Argument übergeben)
    if any(strcmpi('TimePlot', varargin)) && size(T, 2) > 0
        figure;
        plot((T - T(1,1))./60, D./1000);
        xlabel('Time [h]');
        ylabel('Distance [km]');
    end
    
    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end
    
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
        fprintf(' * Tile %s:', tilename);
        
        if ~exist(tilename, 'file')
            subdom = 'abc';
            websave(tilename, sprintf(...
                'http://%c.tile.openstreetmap.org/%d/%d/%d.png', ...
                subdom(randi(3, 1)), zlevel, x, y));
            fprintf(' downloaded.\n');
        else
            fprintf(' found.\n');
        end
        
        % für Benutzung von image anpassen
        [tileimg, tmap] = imread(tilename);
        if ~isempty(tmap)
            tileimg = ind2rgb(tileimg, tmap);
        end
    end

    function tileBackground(xrange, yrange)
        ax.XLim = xrange; ax.YLim = yrange;
        drawnow;
        
        % Errechne angemessenes Zoom-Level aus Plot-Größe
        if strcmpi(ax.Units, 'normalized')
            pixelheight = ax.Parent.Position(4) * ax.Position(4);
        else
            pixelheight = ax.Position(4);
        end
        
        zlevel_ur = log2((pixelheight * maxLat)/(range(yrange)*256)) + 1;
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

        for xx=xmin:xmax
            for yy=ymin:ymax
                TILE = gettile(xx, yy, zlevel);

                image('XData', cornerLon((xx:xx+1)-xmin+1), ...
                      'YData', cornerLat((yy:yy+1)-ymin+1), ...
                      'CData', TILE);
            end
        end
    end
end