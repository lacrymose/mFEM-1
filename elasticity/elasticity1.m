function u = elasticity1(node,elem,pde,bdFlag)
%Elasticity  Conforming P1 elements discretization of linear elasticity equation
%
%       u = [ u1, u2]
%       -mu \Delta u - (lambda + mu)*grad(div(u)) = f in \Omega
%       Dirichlet boundary condition u = [g1_D, g2_D] on \Gamma_D.
%

N = size(node,1); NT = size(elem,1); Ndof = 3;
mu = pde.mu; lambda = pde.lambda; f = pde.f;
% -------------- Compute (Dibase,Djbase) --------------------
[Dphi,area] = gradbasis(node,elem);
Dbase = cell(2,2);
for i = 1:2
    for j = 1:2
        k11 = Dphi(:,i,1).*Dphi(:,j,1).*area;
        k12 = Dphi(:,i,1).*Dphi(:,j,2).*area;
        k13 = Dphi(:,i,1).*Dphi(:,j,3).*area;
        k21 = Dphi(:,i,2).*Dphi(:,j,1).*area;
        k22 = Dphi(:,i,2).*Dphi(:,j,2).*area;
        k23 = Dphi(:,i,2).*Dphi(:,j,3).*area;
        k31 = Dphi(:,i,3).*Dphi(:,j,1).*area;
        k32 = Dphi(:,i,3).*Dphi(:,j,2).*area;
        k33 = Dphi(:,i,3).*Dphi(:,j,3).*area;
        K = [k11,k12,k13,k21,k22,k23,k31,k32,k33]; % stored in rows
        Dbase{i,j} = K(:); % straighten
    end
end

% -------- Sparse assembling indices -----------
nnz = NT*Ndof^2;
ii = zeros(nnz,1); jj = zeros(nnz,1);
id = 0;
for i = 1:Ndof
    for j = 1:Ndof
        ii(id+1:id+NT) = elem(:,i);   % zi
        jj(id+1:id+NT) = elem(:,j);   % zj
        id = id + NT;
    end
end
% ----------- Assemble stiffness matrix -----------
% (grad u,grad v)
ss11 = Dbase{1,1}+Dbase{2,2};  ss22 = ss11;
A11 = sparse(ii,jj,ss11,N,N); A12 = sparse(N,N);
A21 = sparse(N,N);            A22 = sparse(ii,jj,ss22,N,N);
A = [A11,A12; A21,A22];
A = mu*A;

% (div u,div v)
ss11 = Dbase{1,1};            ss12 = Dbase{1,2};
ss21 = Dbase{2,1};            ss22 = Dbase{2,2};
B11 = sparse(ii,jj,ss11,N,N); B12 = sparse(ii,jj,ss12,N,N);
B21 = sparse(ii,jj,ss21,N,N); B22 = sparse(ii,jj,ss22,N,N);
B = [B11,B12; B21,B22];
B = (lambda+mu)*B;

% stiff matrix
kk = A + B;

% ------------- Assemble load vector ------------
% % mid-point quadrature rule
% x1 = node(elem(:,1),1); y1 = node(elem(:,1),2);
% x2 = node(elem(:,2),1); y2 = node(elem(:,2),2);
% x3 = node(elem(:,3),1); y3 = node(elem(:,3),2);
% xc = 1/3*(x1+x2+x3); yc = 1/3*(y1+y2+y3); pc = [xc,yc];
% f1 = f(pc).*area./3; f2 = f1; f3 = f1;

% Gauss quadrature rule
[lambda,weight] = quadpts(2);
f1 = zeros(NT,2); f2 = f1; f3 = f1;
weight = [weight(:),weight(:)];
for iel = 1:NT
    vK = node(elem(iel,:),:); % vertices of K
    xy = lambda*vK;  fxy = f(xy); % fxy = [f1xy,f2xy]
    fv1 = fxy.*[lambda(:,1),lambda(:,1)]; % (f,phi1)
    fv2 = fxy.*[lambda(:,2),lambda(:,2)]; % (f,phi2)
    fv3 = fxy.*[lambda(:,3),lambda(:,3)]; % (f,phi3)
    
    f1(iel,:) = area(iel)*dot(weight,fv1);
    f2(iel,:) = area(iel)*dot(weight,fv2);
    f3(iel,:) = area(iel)*dot(weight,fv3);
end
F1 = [f1(:,1),f2(:,1),f3(:,1)]; F1 = F1(:);
F2 = [f1(:,2),f2(:,2),f3(:,2)]; F2 = F2(:);
ff1 = accumarray(elem(:), F1,[N 1]);
ff2 = accumarray(elem(:), F2,[N 1]);
ff = [ff1;ff2];

% ------------ Dirichlet boundary condition ----------------
g_D = pde.g_D;  eD = bdFlag.eD;
isBdNode = false(N,1); isBdNode(eD) = true;
bdNode = find(isBdNode); freeNode = find(~isBdNode);
pD = node(bdNode,:);
bdDof = [bdNode; bdNode+N]; freeDof = [freeNode;freeNode+N];
u = zeros(2*N,1); uD = g_D(pD); u(bdDof) = uD(:);
ff = ff - kk*u;

% ------------------ Solver -------------------
u(freeDof) = kk(freeDof,freeDof)\ff(freeDof);