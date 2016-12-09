% Erste Versuche

bounds = [50.735 7.145 50.755 7.165];

tic
% API-Query muss noch angepasst werden
api_name = sprintf(...
    'http://overpass-api.de/api/interpreter?data=(way["highway"](%f,%f,%f,%f);>;);out;',...
    bounds);

remote_xml = webread(api_name);
toc
indices = strfind(remote_xml, '<node');
index = indices(1);

remote_xml = sprintf(...
    '%s<bounds minlat="%f" minlon="%f" maxlat="%f" maxlon="%f"/>\n  %s', ...
    remote_xml(1:index-1), bounds, remote_xml(index:end));

%filename = '../../OSMmatlab/map.osm';
filename = sprintf('map-%f_%f_%f_%f.osm', bounds);
fid = fopen(filename, 'wt');
fprintf(fid, '%s', remote_xml);
fclose(fid);
%%

tic;
[parsed_osm, osm_xml] = parse_openstreetmap(filename);

[connectivity_matrix, intersection_node_indices] = extract_connectivity(parsed_osm);
toc;

dg = or(connectivity_matrix, connectivity_matrix.');

%%

curr_coord = [7.157; 50.749]; % Spaltenvektor!

nearest_node_idx = findNearestVec(curr_coord, parsed_osm.node.xy);

possible_next = find(dg(:, nearest_node_idx)); % Indizes adjazenter Knoten

