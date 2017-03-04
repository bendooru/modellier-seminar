function p = lonlat2vec(lon, lat, r)
    % LONLAT2VEC konvertiere Breiten- und Längengrad in einen 3D-Vektor
    %   Aufruf: p = lonlat2vec(lon, lat, r) mit
    %   lon     Längengrad in Grad
    %   lat     Breitengrad in Grad
    %   r       Radius der zugrundeliegenden Kugel
    p = zeros(3,1);
    [p(1), p(2), p(3)] = sph2cart(deg2rad(lon), deg2rad(lat), r);
end