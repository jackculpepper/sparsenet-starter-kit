function [f, g] = objfun_a(x0, phi, I, lambda);

[L M] = size(phi);

B = size(I,2);

a = reshape(x0,M,B);

E = I - phi*a;

f_recon = 0.5*sum(E(:).^2);
f_sparse = lambda*sum(abs((a(:))));

f = f_recon + f_sparse;

df = -(phi'*E) + lambda*sign(a);
g = df(:);

