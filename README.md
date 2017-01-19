# Modellierungsseminar

Repository zur Speicherung relevanter Dateien:

* `matlab` enthält Matlab-Dateien des Sonnen-Modells.
 * erfordert nun Matlab-Extradateien `readhgt` im Matlab-Pfad
 * Infos zur Overpass-OSM-API: https://wiki.openstreetmap.org/wiki/Overpass_API
 * Details zur Berechnung von Kachelnamen: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
 * Funktion `follow_osm` berechnet Route ausgehend von Straßen- und Weg-Daten.
   Heruntergeladene .osm-Dateien werden im Unterverzeichnis `maps` gespeichert. Die Funktion
   hat folgende optionale Argumente:
    * `'Animate'`: Animiert gefundene Route
    * `'Elevation'`: Verwendet Höhendaten bei Berechnung der Geschwindigkeit
    * `'LinePlot'`: Plotte umliegende Straßen aus osm-Dateien, anstatt Rastergrafiken zu unterlegen
    * `'TimePlot'`: Plotte zusätzlich zurückgelegte Distanz nach Zeit
 * `.hgt`-Dateien werden nun im Unterverzeichnis `hgt` gespeichert, um den Hauptorder
   nicht zuzumüllen. Das `readhgt`-Skript scheint Probleme beim Verbinden über http zu
   haben.
* `vorstellung` enthält Dateien der Projektvorstellung.
* `zwischenber1` enthält Dateien zum ersten Zwischenbericht.
* `zwischenber2` enthält Dateien zum zweiten Zwischenbericht.
* `zwischenber3` enthält Dateien zum dritten Zwischenbericht.
