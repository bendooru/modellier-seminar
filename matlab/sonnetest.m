steps = 10000;
X = zeros(steps,1);
Y = zeros(steps,1);
Z = zeros(steps,1);

for i=1:steps;
    v = sonnen_pos(i*30);
    X(i) = v(1); Y(i) = v(2); Z(i) = v(3);
end

plot3(X, Y, Z);