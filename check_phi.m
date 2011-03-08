
L = 5;
M = 4;
B = 3;

a = randn(M,B);
phi = randn(L,M);
I = randn(L,B);

lambda = 0.1;
gamma = 0.2;

checkgrad('objfun_phi', phi(:), 0.01, a, I, lambda, gamma)

