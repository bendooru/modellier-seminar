setenv('MATLAB_SUNPOSITION_FUN', '');
osm_test; clc;

plot(X(1, :), X(2, :)); hold on;

setenv('MATLAB_SUNPOSITION_FUN', 'exact');
osm_test;

plot(X(1, :), X(2, :), '--'); hold off;

legend('eigene Version', 'exakte Version')