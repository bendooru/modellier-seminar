function X = follow_osm(lon, lat, speed, tag)
    coord = [lon; lat];
    earth_radius = 6371000;
    p = lonlat2vec(lon, lat, earth_radius);
    [t_0, visible] = sonnenaufgang(p, tag);
    
    bounds = [lat-0.035 lon-0.035 lat+0.035 lon+0.035];
    
    while boundaryDistance > 0.0001 && visible
        break;
    end
    
    function d = boundaryDistance
        if all(coord' < bounds([2 1])) || all(coord' > bounds([4 3]))
            d = 0;
        else
            d = min(abs(bounds([2 1 4 3]) - repmat(coord', 1, 2)));
        end
    end
end