function v = sonnen_pos(t)
    % SONNEN_POS Berechnet die derzeitige Position der Sonne als 3D-Vektor
    %   Aufruf: v = sonnen_pos(t) mit
    %   t   Zeitpunkt in unserem Zeitformat (min seit 1.1. 00:00 UTC)
    %   v   Position der Sonne als dreidimensionaler Vektor in unserem geozentrischen
    %   	Modell
    %
    %   Funktionsweise siehe Ausarbeitung bzw. Folien
    tag = 1440; % minuten
    t_0 = 172.5*tag; % bestimmter Startwert
         
    t = t - t_0;

    omega_S = (2*pi)/(365*tag);
    dist_S = 149000000000;

    omega_E = (2*pi)/tag;
    alpha_E = -0.13*pi; % Erdachsenneigung
    
    dreh_Y = [  cos(alpha_E), 0, sin(alpha_E);
               0           1, 0;
               -sin(alpha_E), 0, cos(alpha_E)
             ];
         
    dreh_Z = [  cos(omega_E*t), sin(omega_E*t), 0;
               -sin(omega_E*t), cos(omega_E*t), 0;
               0,               0,              1
             ];
         
    v = dist_S .* (dreh_Z * dreh_Y * [ cos(omega_S*t); sin(omega_S*t); 0 ]);
end