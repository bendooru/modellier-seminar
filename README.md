# Modellierungsseminar

Repository zur Speicherung relevanter Dateien:

* `matlab` enthält Matlab-Dateien des Sonnen-Modells.
 * erfordert nun Matlab-Extradateien `readhgt` im Matlab-Pfad
 * Matlab-Skript SunAzEl zur genauen Bestimmung des Sonnenstandes: https://de.mathworks.com/matlabcentral/fileexchange/23051-vectorized-solar-azimuth-and-elevation-estimation
 * Infos zur Overpass-OSM-API: [Link](https://wiki.openstreetmap.org/wiki/Overpass_API)
 * Details zur Berechnung von Kachelnamen: [Link](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
 * [GUI Layout Toolbox](https://de.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox?requestedDomain=www.mathworks.com)
   liefert etwas bessere Ergebnisse bei GUI-Erstellung.
   [Dokumentation](http://cda.psych.uiuc.edu/matlab_programming_class_2012/guide/GUILayout_v1p10/GUILayout-v1p10/layoutHelp/index.html).
 * Funktion `follow_osm` berechnet Route ausgehend von Straßen- und Weg-Daten.
   Heruntergeladene .osm-Dateien werden im Unterverzeichnis `maps` gespeichert.
 * In `osm_gui` wird `follow_osm` um grafische Ein- und Ausgabe erweitert (bisher nicht für Datum
   und Fitness-Profil). Die Funktion hat folgende optionale Argumente:
    * `'Animate'`: Animiert gefundene Route
    * `'NoElevation'`: Verwendet keine Höhendaten bei Berechnung der Geschwindigkeit
    * `'TimePlot'`: Plotte zusätzlich zurückgelegte Distanz nach Zeit
    * Ein Aufruf der Form `osm_gui(_, 'Coord', [lon lat])` überspringt die grafische
      Koordinatenwahl
 * `Gui` oder `SonneGUI` stellen vollständife GUIs dar (letzteres braucht die GUI Layout Toolbox
 * `.hgt`-Dateien werden nun im Unterverzeichnis `hgt` gespeichert, um den Hauptorder
   nicht zuzumüllen. Das `readhgt`-Skript scheint Probleme beim Verbinden über http zu
   haben.
* `vorstellung` enthält Dateien der Projektvorstellung.
* `zwischenber1` enthält Dateien zum ersten Zwischenbericht.
* `zwischenber2` enthält Dateien zum zweiten Zwischenbericht.
* `zwischenber3` enthält Dateien zum dritten Zwischenbericht.
