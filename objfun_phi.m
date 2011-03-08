function [f, g] = objfun_phi(x0, a, I, lambda, gamma);

M = size(a,1);

[L B] = size(I);

phi = reshape(x0,L,M);

E = I - phi*a;

f_recon = 0.5*sum(E(:).^2) / B;
f_sparse = lambda*sum(abs(a(:))) / B;
f_decay = 0.5*gamma*sum(phi(:).^2);

f = f_recon + f_sparse + f_decay;

g = -E*a'/B + gamma*phi;

g = g(:);


