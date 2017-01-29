function SonneGUI
    % Erstellt GUI, beinhaltet entsprechende Funktionen
    % ACHTUNG! Basiert auf Gui Layout Toolbox

    %% Hauptteil
    maxLat = rad2deg(atan(sinh(pi)));
    tiledir = 'tiles';
    mapdir  = 'maps';
    hgtdir  = 'hgt';
    
    guihandles = createGUI;
    
    
    %% Hilfsfunktionen
    function handles = createGUI()
        % Erstellt alle GUI-Elemente, gibt Handle zurück, der diese enthält
        f = figure('Name', 'Immer der Sonn'' entgegen', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'NumberTitle', 'off');
        
        % Menüliste
        mmenu = uimenu(f, 'Label', 'Temporäre Dateien');
        handles.tilemenu = uimenu(mmenu, 'Label', '.png-Tiledaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(~, ~) dirDelFun(tiledir));
        handles.osmmenu = uimenu(mmenu, 'Label', '.osm-Kartendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(~, ~) dirDelFun(mapdir));
        handles.hgtmenu = uimenu(mmenu, 'Label', '.hgt-Höhendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(obj, ~) dirDelFun(obj, hgtdir));
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFun(tiledir, handles.tilemenu);
        dirExFun(mapdir, handles.osmmenu);
        dirExFun(hgtdir, handles.hgtmenu);
        
        bmenu = uimenu(f, 'Label', 'Beispiele');
        loadmenu = uimenu(bmenu, 'Label', 'Beispiel laden ...');
        handles.ClearExMenu = uimenu(bmenu, 'Label', 'Beispiel zurücksetzen', ...
            'Enable', 'off', ...
            'Callback', @clearExampleFcn);
        
        exmfiles = dir(fullfile('beispiele', '*.mat'));
        for i = 1:size(exmfiles, 1)
            filename = fullfile('beispiele', exmfiles(i).name);
            load(filename, 'str');
            uimenu(loadmenu, 'Label', str, ...
            'Callback', @(~, ~) setExampleFcn(filename));
        end
        
        % Menüeintrag zum Beenden des Programms (auch mit Strg-W)
        uimenu(mmenu, 'Label', 'Beenden', 'Accelerator', 'W', ...
            'Separator', 'on', ...
            'Callback', @(~, ~) delete(f));
        
        % Hauptbereich
        mainlayout = uiextras.VBox('Parent', f);
        handles.MainAx = axes('Parent', mainlayout, ...
            'DataAspectRatio', [1 maxLat/180 1], ...
            'Title', 'Kartenbereich', ...
            'XLim', [-180 180], ...
            'YLim', [-maxLat maxLat]);
        
        xlabel(handles.MainAx, 'Longitude (°)');
        ylabel(handles.MainAx, 'Latitude (°)');
        
        % unterer Teil der GUI
        controlpanel = uiextras.Panel('Parent', mainlayout, ...
            'Title', 'Steuerung');
        
        % Horizontale Aufteilung
        buttongroup = uiextras.HBox('Parent', controlpanel);
        
        % Tag-Monat-Eingabefeld
        tagmonatfeld = uiextras.HBox('Parent', ...
            uiextras.BoxPanel('Parent', buttongroup, 'Title', 'Tag, Monat'));
        handles.TagEdit   = uicontrol('Parent', tagmonatfeld, ...
            'Style', 'edit', 'String', '1');
        handles.MonatEdit = uicontrol('Parent', tagmonatfeld, ...
            'Style', 'edit', 'String', '1');
        
        % Eingabefeld für Laufgeschwindigkeit
        laufgeschwfeld = uiextras.BoxPanel('Parent', buttongroup, ...
            'Title', 'Geschw. [m/min]');
        handles.LaufEdit = uicontrol('Parent', laufgeschwfeld, ...
            'Style', 'edit', 'String', '90');
        
        % Eingabefeld für Lauf- und Pausezeiten
        laufpausefeld = uiextras.BoxPanel('Parent', buttongroup, ...
            'Title', 'Lauf-Pause-Intervalle (Komma-getrennt)');
        handles.LaufPauseEdit = uicontrol('Parent', laufpausefeld, ...
            'Style', 'edit', 'String', '180, 30');
        
        % Manuelle Koordinatenwahl
        koordwahlfeld = uiextras.VBox('Parent', buttongroup);
        handles.KoordManuellCheckB = uicontrol('Parent', koordwahlfeld, ...
            'Style', 'checkbox', ...
            'String', 'Koordinaten manuell eingeben', ...
            'Value', 0, ...
            'Callback', @manuellCheckFcn);
        lonlatedits = uiextras.HBox('Parent', koordwahlfeld, 'Visible', 'off');
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lon.:');
        handles.LonEdit = uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0');
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lat.:');
        handles.LatEdit = uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0');
        handles.LonLatEdits = lonlatedits;
       
        % Größen der Felder
        lonlatedits.Sizes = [35 -1 35 -1];
        koordwahlfeld.Sizes = [-1 20];
        
        % Animiercheckbox
        
        handles.AnimateCB = uicontrol('Parent', buttongroup, ...
            'Style', 'checkbox', ...
            'String', 'Animieren', ...
            'Value', 0);
        
        % Zwischenraum
        uiextras.Empty('Parent', buttongroup);
        
        % Animier- und Losknopf am rechten Rand des Programms
        lastbuttons = uiextras.VBox('Parent', buttongroup);
        
        handles.ReAnimateButton = uicontrol('Parent', lastbuttons, ...
            'String', 'Erneut animieren', ...
            'Visible', 'off', ...
            'Callback', @reAnimFcn);
        
        handles.LosButton = uicontrol('Parent', lastbuttons, ...
            'String', 'Los', ...
            'Callback', @startCalcFcn);
        
        buttongroup.Sizes = [90 120 270 250 100 -1 120];
        
        mainlayout.Sizes = [-1 60];
    end

    function clearExampleFcn(obj, ~)
        handles = [guihandles.TagEdit, guihandles.MonatEdit, guihandles.LaufEdit, ...
            guihandles.LaufPauseEdit, guihandles.LonEdit, guihandles.LatEdit];
        set(handles, 'Enable', 'on');
        
        set(obj, 'Enable', 'off');
    end

    function setExampleFcn(fname)
        % lädt Variablen str, coord, tag, monat, fitness, X, T
        loadedvar = load(fname);
        
        set(guihandles.TagEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.tag), 'off' });
        set(guihandles.MonatEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.monat), 'off' });
        
        set(guihandles.LaufEdit, {'String', 'Enable'}, ...
            { sprintf('%d', loadedvar.fitness.f{1}(0)), 'off' });
        lplist = sprintf('%d,', loadedvar.fitness.walkpause);
        set(guihandles.LaufPauseEdit, {'String', 'Enable'}, ...
            { lplist(1:end-1), 'off' });
        
        set(guihandles.KoordManuellCheckB, 'Value', 1);
        manuellCheckFcn(guihandles.KoordManuellCheckB);
        
        set(guihandles.LonEdit, {'String', 'Enable'}, ...
            { sprintf('%f', loadedvar.coord(1)), 'off' });
        set(guihandles.LatEdit, {'String', 'Enable'}, ...
            { sprintf('%f', loadedvar.coord(2)), 'off' });
        
        guihandles.XData = loadedvar.X;
        guihandles.TData = loadedvar.T;
        
        set(guihandles.ClearExMenu, 'Enable', 'on');
    end

    function manuellCheckFcn(hObj, ~)
        if get(hObj, 'Value') == 1
            visval = 'on';
        else
            visval = 'off';
        end
        
        set(guihandles.LonLatEdits, 'Visible', visval);
    end

    % wird bei Druck des 'Los'-Knopfes ausgeführt
    function startCalcFcn(obj, ~)
        % Knopf während Berechnung ausgrauen
        set(obj, 'Enable', 'off');
        set(guihandles.ReAnimateButton, 'Visible', 'off');
        
        % evtl. Fehlerbehandlung hinzufügen
        tag   = str2double(get(guihandles.TagEdit,   'String'));
        monat = str2double(get(guihandles.MonatEdit, 'String'));
        speed = str2double(get(guihandles.LaufEdit, 'String'));
        
        fitness.walkpause = sscanf(get(guihandles.LaufPauseEdit,'String'), '%d,', [2 Inf]);
        % bisher nur konstante Funktion
        fitness.f = { @(t) speed };
        
        % TODO
        animateplot = get(guihandles.AnimateCB, 'Value');
        
        if get(guihandles.KoordManuellCheckB, 'Value') == 0
            coord = chooseStartingPoint(guihandles.MainAx);
        else
            coord(1) = str2double(get(guihandles.LonEdit, 'String'));
            coord(2) = str2double(get(guihandles.LatEdit, 'String'));
        end
    
        tagj = day(tag, monat);
        datum = datestr(datetime('2000-12-31') + tagj, 'mmmm dd');
        guihandles.Datum = datum;
        title(guihandles.MainAx, datum);
        drawnow;
        
        % falls kein Beispiel geladen
        if strcmp(get(guihandles.TagEdit, 'Enable'), 'on')
            % Orte zu südlich oder nördlich beitzen keine Höhendaten
            if abs(coord(2)) > 60
                opt = 'NoElevation';
            else
                opt = 'Elevation';
            end
            [guihandles.XData, ~, guihandles.TData] = ...
                follow_osm(coord(1), coord(2), 1, tagj, fitness, opt);
        end
        
        % beginne Plotten
        hold(guihandles.MainAx, 'on');
    
        cla(guihandles.MainAx);
        % Extrema
        xyRange = minmax(guihandles.XData) + [-0.001, 0.001; -0.001, 0.001];

        tileBackground(xyRange(1, :), xyRange(2, :), guihandles.MainAx);

        if animateplot
            animateRoute(guihandles.XData, guihandles.TData, guihandles.MainAx);
        else
            % normaler, sofortiger Plot
            h = plot(guihandles.MainAx, ...
                guihandles.XData(1, :), guihandles.XData(2, :), '-r', 'LineWidth', 1.5);
            guihandles.RouteLine = h;
        end
        
        set(guihandles.ReAnimateButton, 'Visible', 'on');

        hold(guihandles.MainAx, 'off');
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFun(tiledir, guihandles.tilemenu);
        dirExFun(mapdir, guihandles.osmmenu);
        dirExFun(hgtdir, guihandles.hgtmenu);
        
        % nach Berechnung Los-Knopf wieder freigeben
        set(obj, 'Enable', 'on');
    end

    % Animiere gefundene route erneut
    function reAnimFcn(obj, ~)
        set(obj, 'Enable', 'off');
        
        hold(guihandles.MainAx, 'on');
        delete(guihandles.RouteLine);
        
        if isfield(guihandles, 'PosMarker')
            delete(guihandles.PosMarker);
        end
        
        animateRoute(guihandles.XData, guihandles.TData, guihandles.MainAx);
        hold(guihandles.MainAx, 'off');
        
        set(obj, 'Enable', 'on');
    end

    function animateRoute(X, T, ax)
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
            title(ax, sprintf('%s [%s]', guihandles.Datum, timestr));
            % limitrate erhöht Performance, es wir aber sehr schnell geplottet
            drawnow limitrate;
            
            % Warte 1/60 Sekunde (~ 1 Frame für meiste Bildschirme)
            pause(1/60);
        end
        
        % Mache Handels 'global'
        guihandles.PosMarker = p;
        guihandles.RouteLine = h;
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
    function dirExFun(dir, handle)
        if isdir(dir)
            set(handle, 'Enable', 'on');
        end
    end

    % Ordner-Lösch-Funktion mit Bestätigungsdialog
    function dirDelFun(obj, dir)
        if isdir(dir)
            p = pwd;
            button = questdlg(sprintf('Ordner "%s/%s" wirklich löschen?', p, dir), ...
                'Ordner löschen?', 'Ja', 'Nein', 'Nein');
            if strcmp(button, 'Ja')
                rmdir(dir, 's');
            end
        end
        
        % Aktualisiere Schaltflächen-Status
        dirExFun(dir, obj);
    end
end