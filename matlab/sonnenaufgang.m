function [t_auf, visible, t_unter] = sonnenaufgang(p, tag)
    tag_dauer = 1440;
    % Ausgangzeit sei 12 Uhr UTC an diesem Tag
    t_auf = tag*tag_dauer;
    visible = true;
    
    % falls Sonne sichtbar, gehe solange 1 Minute zurück bis sie nicht mehr
    % sichtbar ist. Dies ist der Sonnenaufgang.
    % Brauchen wir 24 Stunden für diesen Prozess, dann herrscht Polartag und wir
    % geben die Ausgangszeit aus
    while (sun_visible(t_auf))
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
    while (~sun_visible(t_auf))
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
    
    % bestimmt wie in earth_path die Sichtbarkeit über den Winkel zum
    % Normalenvektor der Tangentialebene unsere Position
    function vis = sun_visible(t)
        vis = earth_path(p, t, 1, 100, norm(p));
    end
end