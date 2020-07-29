function bdStruct= setboundary(node,elem,varargin)
% setboundary sets type of boundary edges and returns structure of boundary
% information. 
% varargin: string for Neumann boundary
%
% Copyright (C) Terence Yu.

%% Find boundary edges
% ------- totalEdge ---------
if size(elem,2) == 4
    elem = mat2cell(elem,ones(size(elem,1),1), 4); % rectangle element
end
if iscell(elem)
    shiftfun = @(verts) [verts(2:end),verts(1)];  % or shiftfun = @(verts) circshift(verts,-1);
    T1 = cellfun(shiftfun, elem, 'UniformOutput', false);
    v0 = horzcat(elem{:})'; % the starting points of edges
    v1 = horzcat(T1{:})'; % the ending points of edges
    allEdge = [v0,v1];
else % Triangulation
    allEdge = [elem(:,[2,3]); elem(:,[3,1]); elem(:,[1,2])];
end
totalEdge = sort(allEdge,2);

% --------  counterclockwise bdEdge --------
[~, i1] = unique(totalEdge,'rows');     % first occurrence
[~, i2] = unique(totalEdge(end:-1:1,:),'rows');  
i2 = size(totalEdge,1)+1-i2;            % last occurrence
bdEdge = allEdge(i1(i1==i2),:);

%% Set up boundary edges
nE = size(bdEdge,1);
% initial as Dirichlet (true for Dirichlet, false for Neumann)
IdxD = true(nE,1);
nodebdEdge = (node(bdEdge(:,1),:) + node(bdEdge(:,2),:))/2;
x = nodebdEdge(:,1); y = nodebdEdge(:,2); %#ok<NASGU>
nvar = length(varargin); % 1 * size(varargin,2)
% note that length(varargin) = 1 for bdNeumann = [] or ''
if (nargin==2) || (~isempty(varargin{1})) 
    for i = 1:nvar 
        bdNeumann = varargin{i};
        id = eval(bdNeumann);
        IdxD(id) = false;
    end
end

bdStruct.bdEdge = bdEdge;   % all boundary edges
bdStruct.bdEdgeD = bdEdge(IdxD,:); % Dirichlet boundary edges
bdStruct.bdEdgeN = bdEdge(~IdxD,:); % Neumann boundary edges
bdStruct.bdNodeIdx = unique(bdEdge(IdxD,:)); % Dirichlet boundary nodes
bdEdgeIdx = find(i1==i2);      % indices of all boundary edges
bdStruct.bdEdgeIdx = bdEdgeIdx; 
bdStruct.bdEdgeIdxD = bdEdgeIdx(IdxD); % indices of Dirichelt boundary edges
bdStruct.bdEdgeIdxN = bdEdgeIdx(~IdxD); % indices of Neumann boundary edges