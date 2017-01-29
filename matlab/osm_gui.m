function [X, D, T, ax] = osm_gui(d, m, fitness, varargin)
    % Beispieltext
    
    % figure in die die Karte geplottet wird
    axisString = strcmpi('Axis', varargin);
    if any(axisString)
        try
            ax = varargin{find(axisString, 1)+1};
        catch
            fprintf('Malformed input for argument "Axis"\n');
            return;
        end
    else
        fig = figure;
        ax = axes('Parent', fig);
    end
    
    maxLat = rad2deg(atan(sinh(pi)));
    daspect(ax, [1, maxLat/180, 1]);
    
    ax.XLim = [-180, 180];
    ax.YLim = [-maxLat, maxLat];
    
    xlabel(ax, 'Longitude (°)');
    ylabel(ax, 'Latidude (°)');
    
    drawnow;
    
    coordStr = strcmpi('Coord', varargin);
    setCoordManually = any(coordStr);
    
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
        tileBackground(xRange, yRange, ax);
        hold(ax, 'off');

        if setCoordManually
            try
                % Lese Koordinaten aus nächstem Argument
                coord = varargin{find(coordStr, 1)+1};
            catch
                fprintf('Malformed input\n');
                return;
            end
            break;
        end

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
    
    hold(ax, 'on');
    
    tag = day(d, m);
    datum = datestr(datetime('2000-12-31') + tag, 'mmmm dd');
    title(ax, datum);
    drawnow;
    
    [X, D, T] = follow_osm(coord(1), coord(2), 1, tag, fitness, wbh);
    
    % OSM-Tiles einfügen
    fprintf('Plotting background tiles:\n');
    
    cla(ax);
    % Extrema
    xyRange = minmax(X) + [-0.005, 0.005; -0.005, 0.005];
    
    tileBackground(xyRange(1, :), xyRange(2, :), ax);
    
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
            ax.Title.String = sprintf('%s [%.1f min]', datum, T(1, i) - T(1, 1));
            drawnow;
        end
    else
        % normaler, sofortiger Plot
        plot(ax, X(1, :), X(2, :), '-r', 'LineWidth', 1.5);
    end
    
    hold(ax, 'off');
    fprintf('done.\n');
    
    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end
end