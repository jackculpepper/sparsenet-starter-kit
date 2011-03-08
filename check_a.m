
L = 5;
M = 4;
B = 3;

a = rand(M,B);
phi = rand(L,M);
I = rand(L,B);

lambda = 0.1;

checkgrad('objfun_a', a(:), 0.01, phi, I, lambda)

