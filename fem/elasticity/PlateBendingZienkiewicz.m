function w = PlateBendingZienkiewicz(node,elem,pde,bdStruct)

para = pde.para; f = pde.f; D = para.D; nu = para.nu;
% ------------- Sparse assembling indices ------------
N = size(node,1); NT = size(elem,1); Ndof = 9;
elem2 = [elem, elem+N, elem+2*N];
nnz = NT*Ndof^2;
ii = zeros(nnz,1); jj = zeros(nnz,1);
id = 0;
for i = 1:Ndof
    for j = 1:Ndof
        ii(id+1:id+NT) = elem2(:,i);
        jj(id+1:id+NT) = elem2(:,j);
        id = id + NT;
    end
end

% ---------------- parameters used in computation -----------------------
% xi, eta
x1 = node(elem(:,1),1); y1 = node(elem(:,1),2);
x2 = node(elem(:,2),1); y2 = node(elem(:,2),2);
x3 = node(elem(:,3),1); y3 = node(elem(:,3),2);
xi = [x2-x3, x3-x1, x1-x2]; eta = [y2-y3, y3-y1, y1-y2];
% Gauss quadrature rule
[lambda,weight] = quadpts(3);
nI = length(weight); % number of integration points
% coefficients in the basis functions
c1 = xi(:,1);   d1 = eta(:,1); 
c2 = -xi(:,2);  d2 = -eta(:,2); 
c3 = -[c2,c1,zeros(NT,1)]; d3 = -[d2,d1,zeros(NT,1)];
c4 = [0.5*c1-c2,  0.5*c2-c1,  0.5*(c1+c2)];
d4 = [0.5*d1-d2,  0.5*d2-d1,  0.5*(d1+d2)];

% ------- second derivatives of homogeneous polynomials ----------
[Dphi,area] = gradbasis(node,elem);
Dquad = @(i,j) quadbasis(i,j,Dphi,lambda);
Dtri = @(i,j,k) tribasis(i,j,k,Dphi,lambda);

% ------- second derivatives of basis functions ----------
b11 = zeros(NT,Ndof,nI); b22 = b11; b12 = b11;
for i = 1:3
    % \phi  (11,22,12)
    DD = 3*Dquad(i,i)-2*Dtri(i,i,i)+2*Dtri(1,2,3);
    b11(:,i,:) = DD(:,:,1);
    b22(:,i,:) = DD(:,:,2);
    b12(:,i,:) = DD(:,:,3);
    % \psi (11,22,12)
    DD = c1.*Dtri(i,i,2)+ c2.*Dtri(i,i,1) + c3(:,i).*Dquad(i,i)...
        + c4(:,i).*Dtri(1,2,3);
    b11(:,3+i,:) = DD(:,:,1);
    b22(:,3+i,:) = DD(:,:,2);
    b12(:,3+i,:) = DD(:,:,3);
    % \zeta (11,22,12)
    DD = d1.*Dtri(i,i,2) + d2.*Dtri(i,i,1) + d3(:,i).*Dquad(i,i)...
        + d4(:,i).*Dtri(1,2,3);
    b11(:,6+i,:) = DD(:,:,1);
    b22(:,6+i,:) = DD(:,:,2);
    b12(:,6+i,:) = DD(:,:,3);
end

% ----------- First stiffness matrix -----------
K = zeros(NT,Ndof^2);
for i = 1:Ndof
    j = 1:Ndof; jd = (i-1)*Ndof+1:i*Ndof;
    for p = 1:nI
        Kp = b11(:,i,p).*b11(:,j,p) + b22(:,i,p).*b22(:,j,p) ...
            + nu*(b11(:,i,p).*b22(:,j,p) + b22(:,i,p).*b11(:,j,p)) ...
            + 2*(1-nu)*b12(:,i,p).*b12(:,j,p);
        K(:,jd) = K(:,jd) + weight(p)*Kp;
    end
end
K = D*area.*K;

% ------------- Second stiffness matrix and load vector ------------
G = zeros(NT,Ndof^2); F = zeros(NT,Ndof); 
if isnumeric(para.c), cf = @(xy) para.c+0*xy(:,1); end
for p = 1:nI
    % quadrature points in the x-y coordinate
    pxy = lambda(p,1)*node(elem(:,1),:) ...
        + lambda(p,2)*node(elem(:,2),:) ...
        + lambda(p,3)*node(elem(:,3),:);    
    % basis functions at the p-th quadrture point
    base = zeros(NT,Ndof); 
    for i = 1:3
        % \phi
        lam123 = lambda(p,1).*lambda(p,2).*lambda(p,3);
        base(:,i) = lambda(p,i).^2.*(3-2*lambda(p,i)) + 2*lam123;
        % \psi
        base(:,3+i) = lambda(p,i).^2.*(c1*lambda(p,2) + c2*lambda(p,1) + c3(:,i)) ...
            + c4(:,i)*lam123;
        % \zeta
        base(:,6+i) = lambda(p,i).^2.*(d1*lambda(p,2) + d2*lambda(p,1) + d3(:,i)) ...
            + d4(:,i)*lam123;
    end    
    % Second stiffness matrix
    for i = 1:Ndof
        j = 1:Ndof; jd = (i-1)*Ndof+1:i*Ndof;
        gs = cf(pxy).*base(:,i).*base(:,j);
        G(:,jd) = G(:,jd) + weight(p)*gs;
    end    
    % load vector
    F = F + weight(p)*f(pxy).*base;    
end
G = area.*G; F = area.*F;

% ------------- Assemble stiffness matrix and load vector ------------
kk = sparse(ii,jj,K(:)+G(:),3*N,3*N);
ff = accumarray(elem2(:), F(:), [3*N 1]);

% ------------ Dirichlet boundary conditions ----------------
eD = bdStruct.eD;
id = [eD; eD+N; eD+2*N];
isBdDof = false(3*N,1); isBdDof(id) = true;
bdDof = isBdDof; freeDof = (~isBdDof);
g_D = pde.g_D;  pD = node(eD,:);  Dw = pde.Dw;
wD = g_D(pD);  Dw = Dw(pD); %wxD = Dw(:,1); wyD = Dw(:,2);
w = zeros(3*N,1); w(bdDof) = [wD;Dw(:)];
ff = ff - kk*w;

% ------------------ Solver -------------------
w(freeDof) = kk(freeDof,freeDof)\ff(freeDof);
w = w(1:N);

end

function Dquad = quadbasis(i,j,Dphi,lambda)

    % second derivative of lambda_i*lambda_j
    NT = size(Dphi,1); nI = size(lambda,1);
    Dquad = zeros(NT,nI,3); % [11,22,12]
    Dquad(1:NT,:,1) = 2*Dphi(:,1,i).*Dphi(:,1,j).*ones(1,nI);
    Dquad(1:NT,:,2) = 2*Dphi(:,2,i).*Dphi(:,2,j).*ones(1,nI);
    Dquad(1:NT,:,3) = (Dphi(:,1,i).*Dphi(:,2,j) + Dphi(:,2,i).*Dphi(:,1,j)).*ones(1,nI);
end

function Dtri =  tribasis(i,j,k,Dphi,lambda)

    % second derivative of lambda_i*lambda_j*lambda_k
    NT = size(Dphi,1); nI = size(lambda,1);
    Dtri = zeros(NT,nI,3); % [11,22,12]
    ss  = [1 2 1]; tt = [1 2 2]; 
    for m = 1:3  % loop for [11,22,12]
        s = ss(m); t = tt(m);
        b1 = (Dphi(:,s,i).*Dphi(:,t,j)+Dphi(:,t,i).*Dphi(:,s,j))*lambda(:,k)';
        b2 = (Dphi(:,s,j).*Dphi(:,t,k)+Dphi(:,t,j).*Dphi(:,s,k))*lambda(:,i)';
        b3 = (Dphi(:,s,i).*Dphi(:,t,k)+Dphi(:,t,i).*Dphi(:,s,k))*lambda(:,j)';
        Dtri(1:NT,:,m) = b1 + b2 + b3; 
    end
end