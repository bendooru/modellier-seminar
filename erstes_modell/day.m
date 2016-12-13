function tag_des_Jahres=day(tag,monat)
%Bekommt Tag und Monat (in Zahlen) und gibt ohne berücksichtigung von
%Schaltjahren 
if monat==1
    tag_des_Jahres=tag;
elseif monat==2
    tag_des_Jahres=tag+31;
elseif monat==3
    tag_des_Jahres=tag+31+28;    
elseif monat==4
    tag_des_Jahres=tag+31+28+31;
elseif monat==5
    tag_des_Jahres=tag+31+28+31+30;
elseif monat==6
    tag_des_Jahres=tag+31+28+31+30+31;
elseif monat==7
    tag_des_Jahres=tag+31+28+31+30+31+30;
elseif monat==8
    tag_des_Jahres=tag+31+28+31+30+31+30+31;
elseif monat==9
    tag_des_Jahres=tag+31+f+31+30+31+30+31+31;
elseif monat==10
    tag_des_Jahres=tag+31+28+31+30+31+30+31+31+30;
elseif monat==11
    tag_des_Jahres=tag+31+28+31+30+31+30+31+31+30+31;
elseif monat==12
    tag_des_Jahres=tag+31+28+31+30+31+30+31+31+30+31+30;
end
end