function SonneGUI
    % Erstellt GUI, beinhaltet entsprechende Funktionen
    % ACHTUNG! Basiert auf Gui Layout Toolbox

    %% Hauptteil
    maxLat = rad2deg(atan(sinh(pi)));
    tiledir = 'tiles';
    mapdir  = 'maps';
    hgtdir  = 'hgt';
    
    createGUI;
    
    
    %% Hilfsfunktionen
    function createGUI()
        % Erstellt alle GUI-Elemente, gibt Handle zurück, der diese enthält
        f = figure('Name', 'Immer der Sonn'' entgegen', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'NumberTitle', 'off');
        
        % Menüliste
        mmenu = uimenu(f, 'Label', 'Temporäre Dateien');
        tilemenu = uimenu(mmenu, 'Label', '.png-Tiledaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(~, ~) dirDelFun(tiledir), ...
            'Tag', 'TileMenu');
        osmmenu = uimenu(mmenu, 'Label', '.osm-Kartendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(~, ~) dirDelFun(mapdir), ...
            'Tag', 'OsmMenu');
        hgtmenu = uimenu(mmenu, 'Label', '.hgt-Höhendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(obj, ~) dirDelFun(obj, hgtdir), ...
            'Tag', 'HgtMenu');
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFun(tiledir, tilemenu);
        dirExFun(mapdir, osmmenu);
        dirExFun(hgtdir, hgtmenu);
        
        bmenu = uimenu(f, 'Label', 'Beispiele');
        loadmenu = uimenu(bmenu, 'Label', 'Beispiel laden ...');
        
        % finde .mat-Dateien im beispiel-Ordner und fürge entsprechende Menü-Eintrgäge
        % hinzu
        exmfiles = dir(fullfile('beispiele', '*.mat'));
        for i = 1:size(exmfiles, 1)
            filename = fullfile('beispiele', exmfiles(i).name);
            load(filename, 'str');
            uimenu(loadmenu, 'Label', str, ...
                'Callback', @(hObj, ~) setExampleFcn(hObj, filename));
        end
        
        uimenu(bmenu, 'Label', 'Beispiel zurücksetzen', ...
            'Enable', 'off', ...
            'Callback', @clearExampleFcn, ...
            'Tag', 'ClearExMenu');
        
        % Menüeintrag zum Beenden des Programms (auch mit Strg-W)
        uimenu(mmenu, 'Label', 'Beenden', 'Accelerator', 'W', ...
            'Separator', 'on', ...
            'Callback', @(~, ~) delete(f));
        
        % Hauptbereich
        mainlayout = uiextras.VBox('Parent', f);
        ax = axes('Parent', mainlayout, ...
            'DataAspectRatio', [1 maxLat/180 1], ...
            'XLim', [-180 180], ...
            'YLim', [-maxLat maxLat], ...
            'Tag', 'MainAx');
        
        title(ax, 'Kartenbereich');
        xlabel(ax, 'Longitude (°)');
        ylabel(ax, 'Latitude (°)');
        
        % unterer Teil der GUI
        controlpanel = uiextras.Panel('Parent', mainlayout, ...
            'Title', 'Steuerung');
        
        % Horizontale Aufteilung
        buttongroup = uiextras.HBox('Parent', controlpanel);
        
        % Tag-Monat-Eingabefeld
        tagmonatfeld = uiextras.HBox('Parent', ...
            uiextras.BoxPanel('Parent', buttongroup, 'Title', 'Tag, Monat'));
        uicontrol('Parent', tagmonatfeld, 'Style', 'edit', 'String', '1', ...
            'Tag', 'TagEdit');
        uicontrol('Parent', tagmonatfeld, 'Style', 'edit', 'String', '1', ...
            'Tag', 'MonatEdit');
        
        % Eingabefeld für Laufgeschwindigkeit
        laufgeschwfeld = uiextras.BoxPanel('Parent', buttongroup, ...
            'Title', 'Geschw. [m/min]');
        uicontrol('Parent', laufgeschwfeld, ...
            'Style', 'edit', 'String', '90', ...
            'Tag', 'LaufEdit');
        
        % Eingabefeld für Lauf- und Pausezeiten
        laufpausefeld = uiextras.BoxPanel('Parent', buttongroup, ...
            'Title', 'Lauf-Pause-Intervalle (Komma-getrennt)');
        uicontrol('Parent', laufpausefeld, ...
            'Style', 'edit', 'String', '180, 30', ...
            'Tag', 'LaufPauseEdit');
        
        % Manuelle Koordinatenwahl
        koordwahlfeld = uiextras.VBox('Parent', buttongroup);
        uicontrol('Parent', koordwahlfeld, ...
            'Style', 'checkbox', ...
            'String', 'Koordinaten manuell eingeben', ...
            'Value', 0, ...
            'Callback', @manuellCheckFcn, ...
            'Tag', 'KoordManuellCheckB');
        lonlatedits = uiextras.HBox('Parent', koordwahlfeld, 'Visible', 'off', ...
            'Tag', 'LonLatEdits');
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lon.:');
        uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0', ...
            'Tag', 'LonEdit');
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lat.:');
        uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0', ...
            'Tag', 'LatEdit');
       
        % Größen der Felder
        lonlatedits.Sizes = [35 -1 35 -1];
        koordwahlfeld.Sizes = [-1 -1];
        
        % Animiercheckbox
        uicontrol('Parent', buttongroup, ...
            'Style', 'checkbox', ...
            'String', 'Animieren', ...
            'Value', 0, ...
            'Tag', 'AnimateCB');
        
        % Zwischenraum
        uiextras.Empty('Parent', buttongroup);
        
        % Animier- und Losknopf am rechten Rand des Programms
        lastbuttons = uiextras.VBox('Parent', buttongroup);
        
        uicontrol('Parent', lastbuttons, ...
            'String', 'Route animieren', ...
            'Visible', 'off', ...
            'Callback', @reAnimFcn, ...
            'Tag', 'ReAnimateButton');
        
        uicontrol('Parent', lastbuttons, ...
            'String', 'Los', ...
            'Callback', @startCalcFcn, ...
            'Tag', 'LosButton');
        
        buttongroup.Sizes = [90 120 270 250 100 -1 120];
        
        mainlayout.Sizes = [-1 60];
    end

    function clearExampleFcn(hObj, ~)
        ghandles = guihandles(hObj);
        handles = [ghandles.TagEdit, ghandles.MonatEdit, ghandles.LaufEdit, ...
            ghandles.LaufPauseEdit, ghandles.KoordManuellCheckB, ...
            ghandles.LonEdit, ghandles.LatEdit];
        set(handles, 'Enable', 'on');
        
        set(hObj, 'Enable', 'off');
    end

    function setExampleFcn(hObj, fname)
        ghandles = guihandles(hObj);
        
        % lädt Variablen str, coord, tag, monat, fitness, X, T
        loadedvar = load(fname);
        
        set(ghandles.TagEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.tag), 'off' });
        set(ghandles.MonatEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.monat), 'off' });
        
        set(ghandles.LaufEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.fitness.f{1}(0)), 'off' });
        lplist = sprintf('%d,', loadedvar.fitness.walkpause);
        set(ghandles.LaufPauseEdit, {'String', 'Enable'}, ...
            { lplist(1:end-1), 'off' });
        
        set(ghandles.KoordManuellCheckB, {'Value', 'Enable'}, {1, 'off'});
        manuellCheckFcn(ghandles.KoordManuellCheckB);
        
        set(ghandles.LonEdit, {'String', 'Enable'}, ...
            { sprintf('%f', loadedvar.coord(1)), 'off' });
        set(ghandles.LatEdit, {'String', 'Enable'}, ...
            { sprintf('%f', loadedvar.coord(2)), 'off' });
        
        data = guidata(hObj);
        
        data.XData = loadedvar.X;
        data.TData = loadedvar.T;
        
        guidata(hObj, data);
        
        set(ghandles.ClearExMenu, 'Enable', 'on');
    end

    function manuellCheckFcn(hObj, ~)
        ghandles = guihandles(hObj);
        
        if get(hObj, 'Value') == 1
            visval = 'on';
        else
            visval = 'off';
        end
        
        set(ghandles.LonLatEdits, 'Visible', visval);
    end

    % wird bei Druck des 'Los'-Knopfes ausgeführt
    function startCalcFcn(hObj, ~)
        ghandles = guihandles(hObj);
        
        % Knopf während Berechnung ausgrauen
        set(hObj, 'Enable', 'off');
        set(ghandles.ReAnimateButton, 'Visible', 'off');
        
        % evtl. Fehlerbehandlung hinzufügen
        tag   = str2double(get(ghandles.TagEdit,   'String'));
        monat = str2double(get(ghandles.MonatEdit, 'String'));
        speed = str2double(get(ghandles.LaufEdit, 'String'));
        
        fitness.walkpause = sscanf(get(ghandles.LaufPauseEdit,'String'), '%d,', [2 Inf]);
        % bisher nur konstante Funktion
        fitness.f = { @(t) speed };
        
        % Entnimm Checkbox, ob Plot animiert werden soll
        animateplot = get(ghandles.AnimateCB, 'Value');
        
        if get(ghandles.KoordManuellCheckB, 'Value') == 0
            coord = chooseStartingPoint(ghandles.MainAx);
            set(ghandles.LonEdit, 'String', sprintf('%.6f', coord(1)));
            set(ghandles.LatEdit, 'String', sprintf('%.6f', coord(2)));
        else
            coord(1) = str2double(get(ghandles.LonEdit, 'String'));
            coord(2) = str2double(get(ghandles.LatEdit, 'String'));
        end
        
        data = guidata(hObj);
    
        tagj = day(tag, monat);
        datum = datestr(datetime('2000-12-31') + tagj, 'mmmm dd');
        data.Datum = datum;
        title(ghandles.MainAx, datum);
        drawnow;
        
        % falls kein Beispiel geladen
        if strcmp(get(ghandles.TagEdit, 'Enable'), 'on')
            % Orte zu südlich oder nördlich beitzen keine Höhendaten
            if abs(coord(2)) > 60
                opt = 'NoElevation';
            else
                opt = 'Elevation';
            end
            
            [data.XData, ~, data.TData] = ...
                follow_osm(coord(1), coord(2), 1, tagj, fitness, opt);
        end
        
        guidata(hObj, data);
        
        % beginne Plotten
        hold(ghandles.MainAx, 'on');
    
        cla(ghandles.MainAx);
        % Extrema
        xyRange = minmax(data.XData) + [-0.001, 0.001; -0.001, 0.001];

        tileBackground(xyRange(1, :), xyRange(2, :), ghandles.MainAx);

        if animateplot
            animateRoute(data.XData, data.TData, ghandles.MainAx);
        else
            % normaler, sofortiger Plot
            h = plot(ghandles.MainAx, ...
                data.XData(1, :), data.XData(2, :), '-r', 'LineWidth', 1.5);
            
            data = guidata(hObj);
            data.RouteLine = h;
            guidata(hObj, data);
        end
        
        set(ghandles.ReAnimateButton, 'Visible', 'on');

        hold(ghandles.MainAx, 'off');
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFun(tiledir, ghandles.TileMenu);
        dirExFun(mapdir, ghandles.OsmMenu);
        dirExFun(hgtdir, ghandles.HgtMenu);
        
        % nach Berechnung Los-Knopf wieder freigeben
        set(hObj, 'Enable', 'on');
    end

    % Animiere gefundene route erneut
    function reAnimFcn(hObj, ~)
        ghandles = guihandles(hObj);
        data = guidata(hObj);
        
        set(hObj, 'Enable', 'off');
        
        hold(ghandles.MainAx, 'on');
        delete(data.RouteLine);
        
        if isfield(data, 'PosMarker')
            delete(data.PosMarker);
        end
        
        guidata(hObj, data);
        
        animateRoute(data.XData, data.TData, ghandles.MainAx);
        hold(ghandles.MainAx, 'off');
        
        set(hObj, 'Enable', 'on');
    end

    function animateRoute(X, T, ax)
        data = guidata(ax);
        
        h = animatedline('Color', 'r', 'LineWidth', 1.5);
        p = plot(ax, X(1, 1), X(2, 1), 'o', 'MarkerFaceColor', 'red');
        
        for i = 1:size(X, 2)
            addpoints(h, X(1, i), X(2, i));
            p.XData = X(1, i);
            p.YData = X(2, i);
            runtime = T(1, i) - T(1, 1);
            if runtime > 59
                timestr = sprintf('%d h %.1f min', floor(runtime/60), mod(runtime, 60));
            else
                timestr = sprintf('%.1f min', runtime);
            end
            title(ax, sprintf('%s [%s]', data.Datum, timestr));
            % limitrate erhöht Performance, es wir aber sehr schnell geplottet
            drawnow limitrate;
            
            % Warte 1/60 Sekunde (~ 1 Frame für meiste Bildschirme)
            pause(1/60);
        end
        
        % Mache Handels 'global'
        data.PosMarker = p;
        data.RouteLine = h;
        
        guidata(ax, data);
    end

    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end

    % Bestimme Startpunkt interaktiv
    function coord = chooseStartingPoint(ax)
        zoomstep = 1;
        button = 0;
        coord = [0,0];

        maxzoom = 15;

        widthhv = 180*[-1, 1];
        heighthv = maxLat*[-1, 1];

        while zoomstep <= maxzoom && button ~= 2
            ax.Title.String = 'Generiere Karte ...';
            drawnow; 
            % Lösche Inhalt des Plots, um Verlangsamung zu verhindern
            cla(ax);

            xRange = arrBounds(coord(1) + widthhv, -180, 180);
            yRange = arrBounds(coord(2) + heighthv, -maxLat, maxLat);

            hold(ax, 'on');
            tileBackground(xRange, yRange, ax);
            hold(ax, 'off');

            if zoomstep == maxzoom
                title(ax, 'Klicken, um Startpunkt zu setzen');
            elseif zoomstep == 1
                title(ax, 'Linksklick: Reinzoomen; Mittelklick: Startpunkt setzen');
            else
                title(ax, 'Linksklick: Reinzoomen; Rechtsklick: Rauszoomen; Mittelklick: Startpunkt setzen');
            end
            drawnow;

            button = [];

            % sorgt dafür, dass nur Maus-Input zählt
            while ~isscalar(button)
                [coord(1), coord(2), button] = ginput(1);
            end

            % halbiere Breite und Höhe des Zoom-Fensters
            if button == 3 && zoomstep > 1
                widthhv = 2.*widthhv;
                heighthv = 2.* heighthv;
                zoomstep = zoomstep-1;
            else
                widthhv = widthhv./2;
                heighthv = heighthv./2;
                zoomstep = zoomstep + 1;
            end
        end
    end
    
    % Funktion für TMP-Datei-Löschmenü
    function dirExFun(dir, hObj)
        if isdir(dir)
            set(hObj, 'Enable', 'on');
        end
    end

    % Ordner-Lösch-Funktion mit Bestätigungsdialog
    function dirDelFun(hObj, dir)
        if isdir(dir)
            p = pwd;
            button = questdlg(sprintf('Ordner "%s/%s" wirklich löschen?', p, dir), ...
                'Ordner löschen?', 'Ja', 'Nein', 'Nein');
            if strcmp(button, 'Ja')
                rmdir(dir, 's');
            end
        end
        
        % Aktualisiere Schaltflächen-Status
        dirExFun(dir, hObj);
    end
end