function tag_des_Jahres=day(tag,monat)
    % Bekommt Tag und Monat (in Zahlen) und gibt ohne Berücksichtigung von
    % Schaltjahren den Tag im Jahr aus
    
    monat_dur = cumsum([0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30]);
    
    tag_des_Jahres = monat_dur(monat) + tag;
end