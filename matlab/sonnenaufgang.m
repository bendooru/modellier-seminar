function [t_auf, visible, t_unter] = sonnenaufgang(p, tag)
    % SONNENAUFGANG Berechne letzten oder nächsten Sonnenunter und -aufgang
    %   Aufruf: [t_auf, visible, t_unter] = sonnenaufgang(p, tag) mit
    %   p       Vektor, der Position beschreibt, an der der Sonnenaufgangszeitpunkt
    %           ermittelt werden soll
    %   tag     Tag als Tag des Jahres, also 1 <= tag <= 365
    %   t_auf   Zeitpunkt des letzten Sonnenaufgangs, falls Sonne zum Zeitpunkt tag*1440
    %           sichtbar ist oder des nächsten Sonnenaufgangs, falls Sonne zu diesem
    %           Zeitpunkt nicht sichtbar
    %   visible true, falls Sonne innerhalt von +-24h sichtbar, entsprechend false, falls
    %           Polarnacht herrscht
    %   t_unter Zeitpunkt des auf t_auf folgenden Sonnenuntergangs, falls dieser weniger
    %           als 1440 min = 24h in der Zukunft liegt
    tag_dauer = 1440;
    % Ausgangzeit sei 12 Uhr UTC an diesem Tag
    t_auf = tag*tag_dauer;
    visible = true;
    
    % falls Sonne sichtbar, gehe solange 1 Minute zurück bis sie nicht mehr
    % sichtbar ist. Dies ist der Sonnenaufgang.
    % Brauchen wir 24 Stunden für diesen Prozess, dann herrscht Polartag und wir
    % geben die Ausgangszeit aus
    while sun_visible(t_auf)
        t_auf = t_auf - 1;
        if t_auf <= (tag-1)*tag_dauer
            t_auf = tag*tag_dauer;
            break;
        end
    end
    
    % falls Sonne nicht sichtbar, gehe solange 1 Minute vor, bis sie sichtbar
    % ist. Dies ist der Sonnenaufgant.
    % Brauchen wir 24 für diesen Prozess, so herscht Polarnacht und wir geben
    % die Ausganszeit aus
    while ~sun_visible(t_auf)
        t_auf = t_auf + 1;
        if t_auf >= (tag+1)*tag_dauer
            t_auf = tag*tag_dauer;
            % für späere Vorhaben: gib Sichtbarkeit aus
            visible = false;
            break;
        end
    end
    
    if visible
        t_unter = t_auf;
        while sun_visible(t_unter) && t_unter < t_auf + 1400
            t_unter = t_unter+1;
        end
    else
        t_unter = t_auf + 1440;
    end
    
    % bestimmt via earth_path die Sichtbarkeit über den Winkel zum
    % Normalenvektor der Tangentialebene unsere Position
    function vis = sun_visible(t)
        vis = earth_path(p, t, 1, 100, norm(p));
    end
end