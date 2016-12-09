function p = lonlat2vec(lon, lat, r)
    p = zeros(3,1);
    [p(1), p(2), p(3)] = sph2cart(deg2rad(lon), deg2rad(lat), r);
end