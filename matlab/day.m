function tdJ=day(tag,monat)
    % DAY Tag des Jahres ausgehend von Tag und Monat
    %   Aufruf: tag_des_Jahres=day(tag,monat)
    %   tag         Tag des Monats
    %   monat       Monat des Jahres
    %   tdJ         Tag des Jahres
    
    % einfache Berechnung über Montatslängen
    monat_dur = cumsum([0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30]);
    
    tdJ = monat_dur(monat) + tag;
end