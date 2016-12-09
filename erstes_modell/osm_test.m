bounds = [50.74 7.15 50.75 7.16];

tic
api_name = ['http://overpass-api.de/api/interpreter?data=(way(' ...
    num2str(bounds(1)) ',' num2str(bounds(2)) ',' num2str(bounds(3)) ...
    ',' num2str(bounds(4)) ');>;);out;'];

remote_xml = webread(api_name);
toc
indices = strfind(remote_xml, '<node');
index = indices(1);

remote_xml = sprintf('%s<bounds minlat="%f" minlon="%f" maxlat="%f" maxlon="%f"/>\n  %s', ...
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

nearest_node_idx = findNearest2(curr_coord, parsed_osm.node.xy);

possible_next = find(dg(:, nearest_node_idx)); % Indizes adjazenter Knoten

