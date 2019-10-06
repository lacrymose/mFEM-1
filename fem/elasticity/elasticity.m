function u = elasticity(node,elem,pde,bdStruct)
%ElasticityVector  Conforming P1 FEM of linear elasticity equation
% Programming in the vectorized finite element space
%
%       u = [u1, u2]
%       -div (sigma) = f in \Omega
%       Dirichlet boundary condition u = [g1_D, g2_D] on \Gamma_D
%       Neumann boundary condition   \sigma*n = g  on \Gamma_N
%       \sigma = (sigma_{ij}): stress tensor, 1<=i,j<=2

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

ii11 = ii;   jj11 = jj;  ii12 = ii;   jj12 = jj+N;
ii21 = ii+N; jj21 = jj;  ii22 = ii+N; jj22 = jj+N;

% ----------- Assemble stiffness matrix -----------
ss11 = (lambda+2*mu)*Dbase{1,1} + mu*Dbase{2,2};
ss12 = lambda*Dbase{1,2} + mu*Dbase{2,1};
ss21 = lambda*Dbase{2,1} + mu*Dbase{1,2};
ss22 = (lambda+2*mu)*Dbase{2,2} + mu*Dbase{1,1};
ii = [ii11; ii12; ii21; ii22];
jj = [jj11; jj12; jj21; jj22];
ss = [ss11; ss12; ss21; ss22];
kk = sparse(ii,jj,ss,2*N,2*N);

% ------------- Assemble load vector ------------
% % mid-point quadrature rule
% x1 = node(elem(:,1),1); y1 = node(elem(:,1),2);
% x2 = node(elem(:,2),1); y2 = node(elem(:,2),2);
% x3 = node(elem(:,3),1); y3 = node(elem(:,3),2);
% xc = 1/3*(x1+x2+x3); yc = 1/3*(y1+y2+y3); pc = [xc,yc];
% 
% f1 = f(pc).*area./3; f2 = f1; f3 = f1;
% F1 = [f1(:,1),f2(:,1),f3(:,1)]; 
% F2 = [f1(:,2),f2(:,2),f3(:,2)]; 

% Gauss quadrature rule
[lambda,weight] = quadpts(2);
f1 = zeros(NT,2); f2 = f1; f3 = f1;
for iel = 1:NT
    vK = node(elem(iel,:),:); % vertices of K
    xy = lambda*vK;  fxy = f(xy); % fxy = [f1xy,f2xy]
    fv1 = fxy.*[lambda(:,1),lambda(:,1)]; % (f,phi1)
    fv2 = fxy.*[lambda(:,2),lambda(:,2)]; % (f,phi2)
    fv3 = fxy.*[lambda(:,3),lambda(:,3)]; % (f,phi3)

    f1(iel,:) = area(iel)*weight*fv1;
    f2(iel,:) = area(iel)*weight*fv2;
    f3(iel,:) = area(iel)*weight*fv3;
end
F1 = [f1(:,1),f2(:,1),f3(:,1)];
F2 = [f1(:,2),f2(:,2),f3(:,2)];
ff = accumarray([elem(:);elem(:)+N], [F1(:);F2(:)], [2*N 1]);

% ------------ Neumann boundary condition ----------------
elemN = bdStruct.elemN;
if ~isempty(elemN)
    g_N = pde.g_N;
    z1 = node(elemN(:,1),:); z2 = node(elemN(:,2),:);
    e = z1-z2;  % e = z2-z1
    ne = [-e(:,2),e(:,1)]; % scaled ne
    Sig1 = g_N(z1); Sig2 = g_N(z2);
    F11 = sum(ne.*Sig1(:,[1,3]),2)./2; F12 = sum(ne.*Sig2(:,[1,3]),2)./2; % g1
    F21 = sum(ne.*Sig1(:,[3,2]),2)./2; F22 = sum(ne.*Sig2(:,[3,2]),2)./2;
    FN = [F11,F12,F21,F22];
    ff = ff + accumarray([elemN(:); elemN(:)+N], FN(:),[2*N 1]);
end

% ------------ Dirichlet boundary condition ----------------
g_D = pde.g_D;  eD = bdStruct.eD;
isBdNode = false(N,1); isBdNode(eD) = true;
bdNode = find(isBdNode); freeNode = find(~isBdNode);
pD = node(bdNode,:);
bdDof = [bdNode; bdNode+N]; freeDof = [freeNode;freeNode+N];
u = zeros(2*N,1); uD = g_D(pD); u(bdDof) = uD(:);
ff = ff - kk*u;

% ------------------ Solver -------------------
u(freeDof) = kk(freeDof,freeDof)\ff(freeDof);