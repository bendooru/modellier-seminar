function SonneGUI
    % SONNEGUI Erstellt GUI zur Interaktion mit unseren Laufmodellen
    % ACHTUNG! Basiert auf Gui Layout Toolbox

    %% Hauptteil
    maxLat = pi;
    % Benutze absolute Pfade, falls SonneGUI nicht aus dem enthaltenden Verzeichnis
    % aufgerufen wird
    tiledir    = fullfile(fileparts(mfilename('fullpath')),'tiles');
    mapdir     = fullfile(fileparts(mfilename('fullpath')),'maps');
    mapfreedir = fullfile(fileparts(mfilename('fullpath')),'maps-free');
    hgtdir     = fullfile(fileparts(mfilename('fullpath')),'hgt');
    
    createGUI;
    
    %% Hilfsfunktionen
    % erstellt alle Gui-Objekte
    function createGUI()
        % Erstellt alle GUI-Elemente, gibt Handle zurück, der diese enthält
        f = figure('Name', 'Immer der Sonn'' entgegen', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'NumberTitle', 'off');
        
        % Menüliste
        % allgemeine Menüeinträge
        mmenu = uimenu(f, ...
            'Label', 'Allgemein');
        uimenu(mmenu, ...
            'Label', 'Laufe nur entlang Straßen', 'Checked', 'on', ...
            'Callback', @osmFunMenuFun, ...
            'Tag', 'OsmFunMenu');
        tilemenu = uimenu(mmenu, ...
            'Label', 'PNG-Tiledaten löschen', ...
            'Enable', 'off', ...
            'Separator', 'on', ...
            'Callback', @(hObj, ~) dirDelFcn(hObj, tiledir), ...
            'Tag', 'TileMenu');
        osmmenu = uimenu(mmenu, ...
            'Label', 'OSM-Kartendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(hObj, ~) dirDelFcn(hObj, mapdir), ...
            'Tag', 'OsmMenu');
        osmfreemenu = uimenu(mmenu, ...
            'Label', 'OSM-Kartendaten ohne Straßen löschen', ...
            'Enable', 'off', ...
            'Callback', @(hObj, ~) dirDelFcn(hObj, mapfreedir), ...
            'Tag', 'OsmFreeMenu');
        hgtmenu = uimenu(mmenu, ...
            'Label', 'HGT-Höhendaten löschen', ...
            'Enable', 'off', ...
            'Callback', @(hObj, ~) dirDelFcn(hObj, hgtdir), ...
            'Tag', 'HgtMenu');
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFcn(tiledir, tilemenu);
        dirExFcn(mapdir, osmmenu);
        dirExFcn(mapfreedir, osmfreemenu);
        dirExFcn(hgtdir, hgtmenu);
        
        % Menüeintrag zum Beenden des Programms (auch mit Strg-W)
        uimenu(mmenu, ...
            'Label', 'Beenden', ...
            'Accelerator', 'W', ...
            'Separator', 'on', ...
            'Callback', @(~, ~) delete(f));
        
        zmenu = uimenu(f, ...
            'Label', 'Zoom-Modus');
        uimenu(zmenu, ...
            'Label', 'Karten-Zoom aktivieren', ...
            'Enable', 'off', ...
            'Callback', @zoomStartFcn, ...
            'Tag', 'ZoomStartMenu');
        uimenu(zmenu, ...
            'Label', 'Zoom zurücksetzen', ...
            'Enable', 'off', ...
            'Callback', @zoomResetFcn, ...
            'Tag', 'ZoomResetMenu');
        
        bmenu = uimenu(f, ...
            'Label', 'Beispiele');
        loadmenu = uimenu(bmenu, ...
            'Label', 'Beispiel laden ...', ...
            'Tag', 'ExmMenu');
        
        % finde .mat-Dateien im beispiel-Ordner und fürge entsprechende Menü-Eintrgäge
        % hinzu
        exmfiles = dir(fullfile('beispiele', '*.mat'));
        for i = 1:size(exmfiles, 1)
            filename = fullfile('beispiele', exmfiles(i).name);
            loadedvar = load(filename, 'str');
            if isfield(loadedvar, 'str')
                uimenu(loadmenu, ...
                    'Label', loadedvar.str, ...
                    'UserData', filename, ...
                    'Callback', @(hObj, ~) setExampleFcn(hObj, filename));
            end
        end
        
        uimenu(bmenu, 'Label', 'Beispiel zurücksetzen', ...
            'Enable', 'off', ...
            'Callback', @clearExampleFcn, ...
            'Tag', 'ClearExMenu');
        
        uimenu(bmenu, 'Label', 'Momentane Daten speichern', ...
            'Enable', 'off', ...
            'CallBack', @saveDataFcn, ...
            'Separator', 'on', ...
            'Tag', 'SaveExpMenu');
        
        uimenu(bmenu, ...
            'Label', 'Eigene Beispiele löschen', ...
            'Separator', 'on', ...
            'Callback', @exDelFcn);
        
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
        
        set(ax, 'YTickLabel', cellstr(num2str(toMercator(...
            get(ax, 'YTick')'))));
        
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
        lonlatedits = uiextras.HBox('Parent', koordwahlfeld);
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lon.:');
        uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0', ...
            'Enable', 'off', ...
            'Tag', 'LonEdit');
        uicontrol('Parent', lonlatedits, 'Style', 'text', 'String', 'Lat.:');
        uicontrol('Parent', lonlatedits, ...
            'Style', 'edit', 'String', '0', ...
            'Enable', 'off', ...
            'Tag', 'LatEdit');
       
        % Größen der Felder
        lonlatedits.Sizes = [35 -1 35 -1];
        koordwahlfeld.Sizes = [-1 -1];
        
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
        
        buttongroup.Sizes = [90 120 270 250 -1 120];
        
        mainlayout.Sizes = [-1 60];
    end

    function clearExampleFcn(hObj, ~)
        ghandles = guihandles(hObj);
        
        handles = [ghandles.TagEdit, ghandles.MonatEdit, ghandles.LaufEdit, ...
            ghandles.LaufPauseEdit, ghandles.KoordManuellCheckB, ...
            ghandles.LonEdit, ghandles.LatEdit];
        set(handles, 'Enable', 'on');
        
        set(ghandles.ExmMenu.Children, 'Checked', 'off');
        set(hObj, 'Enable', 'off');
    end

    function setExampleFcn(hObj, fname)
        ghandles = guihandles(hObj);
        
        % versehe jetziges Beispiel mit Auswahlhaken
        set(ghandles.ExmMenu.Children, 'Checked', 'off');
        set(hObj, 'Checked', 'on');
        
        % lädt Variablen str, coord, tag, monat, fitness, X, T
        loadedvar = load(fname);
        
        % Existierende Beispiele sollen nicht nocheinmal gespeichert werden können
        set(ghandles.SaveExpMenu, 'Enable', 'off');
        
        set(ghandles.TagEdit, ...
            { 'String',                     'Enable' }, ...
            { sprintf('%d', loadedvar.tag), 'off' });
        set(ghandles.MonatEdit, ...
            { 'String',                       'Enable' }, ...
            { sprintf('%d', loadedvar.monat), 'off' });
        
        % sicherheitshalber prüfen, ob Cell-Array
        if iscell(loadedvar.fitness.f)
            fun = loadedvar.fitness.f{1};
        else
            fun = loadedvar.fitness.f;
        end
        
        set(ghandles.LaufEdit, ...
            { 'String',                                 'Enable'}, ...
            { sprintf('%d', fun(0)), 'off' });
        lplist = sprintf('%d,', loadedvar.fitness.walkpause);
        set(ghandles.LaufPauseEdit, ...
            { 'String',        'Enable' }, ...
            { lplist(1:end-1), 'off' });
        
        set(ghandles.KoordManuellCheckB, ...
            { 'Value', 'Enable' }, ...
            { 1,       'off' });
        manuellCheckFcn(ghandles.KoordManuellCheckB);
        
        set(ghandles.LonEdit, ...
            { 'String',                          'Enable'}, ...
            { sprintf('%f', loadedvar.coord(1)), 'off' });
        set(ghandles.LatEdit, ...
            { 'String',                          'Enable'}, ...
            { sprintf('%f', loadedvar.coord(2)), 'off' });
        
        data = guidata(hObj);
        
        data.XData = loadedvar.X;
        data.TData = loadedvar.T;
        
        guidata(hObj, data);
        
        startCalcFcn(ghandles.LosButton);
        
        set(ghandles.ClearExMenu, 'Enable', 'on');
    end

    function saveDataFcn(hObj, ~)
        ghandles = guihandles(hObj);
        data = guidata(hObj);
        
        X = data.XData;
        T = data.TData;
        coord(1) = str2double(get(ghandles.LonEdit, 'String'));
        coord(2) = str2double(get(ghandles.LatEdit, 'String'));
        fitness.walkpause = sscanf(get(ghandles.LaufPauseEdit,'String'), '%d,', [2 Inf]);
        speed = str2double(get(ghandles.LaufEdit, 'String'));
        fitness.f = { @(t) (speed) };
        tag   = str2double(get(ghandles.TagEdit,   'String'));
        monat = str2double(get(ghandles.MonatEdit, 'String'));
        
        titstr = inputdlg('Kurzer Titel für Beispiel');
        
        str = sprintf('%s [%.6f, %.6f] (%d/%d)\n', titstr{1}, coord, tag, monat);
        
        n = size(dir(fullfile('beispiele', 'beispiel-*.mat')), 1);
        filename = sprintf('beispiel-%04d.mat', n+1);
        
        while size(dir(fullfile('beispiele', filename)), 1) > 0
            n = n+1;
            filename = sprintf('beispiel-%04d.mat', n);
        end
        
        filename = fullfile('beispiele', filename);
        
        % speichere benötigte Variablen
        save(filename, 'str', 'coord', 'fitness', 'tag', 'monat', 'X', 'T');
        
        % füge Beispiel direkt dem Menü hinzu
        uimenu(ghandles.ExmMenu, ...
            'Label', str, ...
            'UserData', filename, ...
            'Callback', @(hObj, ~) setExampleFcn(hObj, filename));
        
        set(hObj, 'Enable', 'off');
    end

    % Lösche selbst erstellte Beispiele
    function exDelFcn(hObj, ~)
        ghandles = guihandles(hObj);
        
        % selbst erstelle Beispiele haben beispiel-Präfix
        eigeneBsp = dir(fullfile('beispiele', 'beispiel*'));
        
        % Zu löschende Dateien
        fnames = fullfile('beispiele', {eigeneBsp.name});
        
        % Liste aller Beispieldateien
        bspFnames = {ghandles.ExmMenu.Children.UserData};
        
        % finde Indizes der zu löschenden Einträge
        [~, ~, menuIdx] = intersect(fnames, bspFnames);
        
        fnamestr = sprintf(' - %s\n', fnames{:});

        button = questdlg(sprintf('Folgende Dateien wirklich löschen?\n%s', fnamestr), ...
            'Dateien löschen?', 'Ja', 'Nein', 'Nein');
        if strcmp(button, 'Ja')
            delete(ghandles.ExmMenu.Children(menuIdx));
            delete(fnames{:});
        end
    end

    function manuellCheckFcn(hObj, ~)
        ghandles = guihandles(hObj);
        
        if get(hObj, 'Value') == 1
            enval = 'on';
        else
            enval = 'off';
        end
        
        set([ghandles.LonEdit, ghandles.LatEdit], 'Enable', enval);
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
        
        coord(1) = str2double(get(ghandles.LonEdit, 'String'));
        coord(2) = str2double(get(ghandles.LatEdit, 'String'));
        
        % Ab hier: teste auf valide Eingabe
        monate = [31 28 31 30 31 30 31 31 30 31 30 31];
        
        if any(isnan([tag, monat, speed, coord])) || monat < 1 || monat > 12 || ...
                tag < 1 || tag > monate(monat) || size(fitness.walkpause, 1) ~= 2
            % Irgendeine Eingabe passt nicht
            errordlg('Invalide Eingaben');
            
            set(hObj, 'Enable', 'on');
            return
        end
        
        % Prüfe, ob Koordinaten ausgewählt werden müssen
        if get(ghandles.KoordManuellCheckB, 'Value') == 0
            % bei Herunterladen von Kacheln kann es zu Netzwerkfehlern kommen
            % fange ab und stoppe Ausführung
            try
                coord = chooseStartingPoint(ghandles.MainAx);
            catch
                set(hObj, 'Enable', 'on');
                return
            end
            
            % Schreibe gefundenen Wert in entsprechende Edit-Felder
            set(ghandles.LonEdit, 'String', sprintf('%.6f', coord(1)));
            set(ghandles.LatEdit, 'String', sprintf('%.6f', coord(2)));
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
            
            % Wähle Funktion je nachdem, ob Option gecheckt ist
            if strcmpi(get(ghandles.OsmFunMenu, 'Checked'), 'on')
                follow_fun = @follow_osm;
            else
                follow_fun = @follow_osm_free;
            end
            
            % follow_osm braucht Netzwerkzugriff: fange Fehler ab
            try
                [data.XData, ~, data.TData] = ...
                    follow_fun(coord(1), coord(2), 1, tagj, fitness, opt);
            catch
                set(hObj, 'Enable', 'on');
                return
            end

            % Ermögliche, Daten zu speichern
            set(ghandles.SaveExpMenu, 'Enable', 'on');
        end
        
        guidata(hObj, data);
        
        % beginne Plotten
        hold(ghandles.MainAx, 'on');
        cla(ghandles.MainAx);
        
        % Extrema
        xyRange = minmax(data.XData) + [-0.001, 0.001; -0.001, 0.001];

        try
            tileBackground(xyRange(1, :), xyRange(2, :), ghandles.MainAx);
        catch
            %
        end
        
        % normaler, sofortiger Plot
        h = plot(ghandles.MainAx, ...
            data.XData(1, :), fromMercator(data.XData(2, :)), '-r', 'LineWidth', 1.5);

        data = guidata(hObj);
        data.RouteLine = h;
        guidata(hObj, data);
        
        set(ghandles.ReAnimateButton, 'Visible', 'on');

        hold(ghandles.MainAx, 'off');
        
        % Aktiviere Schaltflächen, falls Ordner existieren
        dirExFcn(tiledir, ghandles.TileMenu);
        dirExFcn(mapdir, ghandles.OsmMenu);
        dirExFcn(mapfreedir, ghandles.OsmFreeMenu);
        dirExFcn(hgtdir, ghandles.HgtMenu);
        
        % nach Berechnung Los-Knopf wieder freigeben
        set([hObj, ghandles.ZoomStartMenu], 'Enable', 'on');
    end

    % Animiere gefundene route erneut
    function reAnimFcn(hObj, ~)
        ghandles = guihandles(hObj);
        data = guidata(hObj);
        
        set([hObj, ghandles.LosButton], 'Enable', 'off');
        
        hold(ghandles.MainAx, 'on');
        delete(data.RouteLine);
        
        if isfield(data, 'PosMarker')
            delete(data.PosMarker);
        end
        
        guidata(hObj, data);
        
        animateRoute(data.XData, data.TData, ghandles.MainAx);
        hold(ghandles.MainAx, 'off');
        
        set([hObj, ghandles.LosButton], 'Enable', 'on');
    end

    function zoomStartFcn(hObj, ~)
        % Funktion führt nur aus, falls sie nicht bereits ausgeführt wird
        if strcmpi(get(hObj, 'Checked'), 'off')
            set(hObj, 'Checked', 'on');
            ghandles = guihandles(hObj);
            
            ax = ghandles.MainAx;
            
            oldtitle = get(get(ax, 'Title'), 'String');
            
            title(ax, 'Linksklick reinzoomen, Rechtsklick rauszoomen, Escape beendet');
            
            zoomCenter = [0;0];
            
            % bleibe im Zoommodus, bis Escape gedrückt wird
            while true
                [zoomCenter(1), zoomCenter(2), button] = ginput(1);
                if ~isscalar(button)
                    continue;
                end
                
                % Fallunterscheidung
                switch button
                    case 27 % Escape
                        break;
                    case 1  % Linksklick
                        zoom = 1;
                    case 3  % Rechtsklick
                        zoom = -1;
                    otherwise
                        continue;
                end
            
                % setze gewählten Punkt als neuen Mittelpunkt
                % halbiere oder verdopple Breite und Höhe je nach Maustaste
                xRange = zoomCenter(1) + (range(ax.XLim)*2.05^(-1-zoom)) .* [-1, 1];
                yRange = zoomCenter(2) + (range(ax.YLim)*2.05^(-1-zoom)) .* [-1, 1];
                
                % Lösche alle Children von ax, die vom Typ Image sind
                delete(ax.Children(strcmpi(get(ax.Children, 'Type'), 'image')));
                
                % zeichne Hintergrund mit neuen Koordinatengrenzen neu
                try
                    tileBackground(xRange, toMercator(yRange), ax);
                catch
                    break;
                end
                    
                
                imgVec = strcmpi(get(ax.Children, 'Type'), 'image');
                % Children von Ax umordnen, damit Route über Kacheln liegt
                set(ax, 'Children', ax.Children([find(not(imgVec)); find(imgVec)]));
            end
            
            title(ax, oldtitle);
            
            set(hObj, 'Checked', 'off');
            set(ghandles.ZoomResetMenu, 'Enable', 'on');
        end
    end

    function zoomResetFcn(hObj, ~)
        ghandles = guihandles(hObj);
        data = guidata(hObj);
        
        xyRange = minmax(data.XData) + [-0.001, 0.001; -0.001, 0.001];
        
        ax = ghandles.MainAx;
        
        % Wiederhole hier das gleiche wie in obiger FUnktion
        delete(ax.Children(strcmpi(get(ax.Children, 'Type'), 'image')));
        
        tileBackground(xyRange(1, :), xyRange(2, :), ghandles.MainAx);
        
        imgVec = strcmpi(get(ax.Children, 'Type'), 'image');
        set(ax, 'Children', ax.Children([find(not(imgVec)); find(imgVec)]));
        
        set(hObj, 'Enable', 'off');
    end

    % plottet gefundene Route als Animation
    function animateRoute(X, T, ax)
        data = guidata(ax);
        
        h = animatedline('Color', 'r', 'LineWidth', 1.5);
        p = plot(ax, X(1, 1), fromMercator(X(2, 1)), 'o', 'MarkerFaceColor', 'red');
        
        for i = 1:size(X, 2)
            addpoints(h, X(1, i), fromMercator(X(2, i)));
            p.XData = X(1, i);
            p.YData = fromMercator(X(2, i));
            runtime = T(1, i) - T(1, 1);
            if runtime > 59
                timestr = sprintf('%d h %.1f min', floor(runtime/60), mod(runtime, 60));
            else
                timestr = sprintf('%.1f min', runtime);
            end
            title(ax, sprintf('%s [%s]', data.Datum, timestr));
            % limitrate erhöht Performance, es wir aber sehr schnell geplottet
            drawnow limitrate;
            
            % Warte 1/60 Sekunde (etwaige Bildwiederholrate der meisten Bildschirme)
            pause(1/60);
        end
        
        % Mache Handles 'global'
        data.PosMarker = p;
        data.RouteLine = h;
        
        guidata(ax, data);
    end

    % beschränke Elemente in Array
    function arr = arrBounds(arr, amin, amax)
        arr = min(max(arr, amin), amax);
    end

    function LAT = toMercator(Y)
        LAT = rad2deg(atan(sinh(Y)));
    end

    function Y = fromMercator(LAT)
        Y = asinh(tan(deg2rad(LAT)));
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
            yRange = toMercator(arrBounds(coord(2) + heighthv, -maxLat, maxLat));

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
        coord(2) = toMercator(coord(2));
    end

    % Toggle Checkbox-Menüeintrag
    function osmFunMenuFun(hObj, ~)
        if strcmpi(get(hObj, 'Checked'), 'on')
            checkval = 'off';
        else
            checkval = 'on';
        end
        set(hObj, 'Checked', checkval);
    end
    
    % Funktion für TMP-Datei-Löschmenü
    function dirExFcn(dir, hObj)
        if isdir(dir)
            set(hObj, 'Enable', 'on');
        else
            set(hObj, 'Enable', 'off');
        end
    end

    % Ordner-Lösch-Funktion mit Bestätigungsdialog
    function dirDelFcn(hObj, dir)
        if isdir(dir)
            p = pwd;
            button = questdlg(sprintf('Ordner "%s/%s" wirklich löschen?', p, dir), ...
                'Ordner löschen?', 'Ja', 'Nein', 'Nein');
            if strcmp(button, 'Ja')
                rmdir(dir, 's');
            end
        end
        
        % Aktualisiere Schaltflächen-Status
        dirExFcn(dir, hObj);
    end
end