# Modellierungsseminar

Repository zur Speicherung relevanter Dateien:

* `erstes_modell` enthält Matlab-Dateien des Sonnen-Modells.
 * erfordert nun Matlab-Extradateien `readhgt` im Matlab-Pfad
 * Infos zur Overpass-OSM-API: https://wiki.openstreetmap.org/wiki/Overpass_API
 * Funktion `follow_osm` berechnet Route ausgehend von Straßen- und Weg-Daten.
   Heruntergeladene .osm-Dateien werden im Unterverzeichnis `maps` gespeichert.
 * `.hgt`-Dateien werden nun im Unterverzeichnis `hgt` gespeichert, um den Hauptorder
   nicht zuzumüllen. Das `readhgt`-Skript scheint Probleme beim Verbinden über http zu
   haben.
* `vorstellung` enthält Dateien der Projektvorstellung.
* `zwischenber1` enthält Dateien zum ersten Zwischenbericht.
* `zwischenber2` enthält Dateien zum zweiten Zwischenbericht.
