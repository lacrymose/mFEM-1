function [node,elem] = uniformrefine(node,elem)
%uniformrefine uniformly refines a 2-D triangulation or quadrilateral mesh

% Copyright (C) Long Chen, modified by Terence Yu. 

%% auxiliary mesh data
allEdge = [elem(:,[2,3]); elem(:,[3,1]); elem(:,[1,2])];
if size(elem,2)==4
    allEdge = [elem(:,[1,2]); elem(:,[2,3]); elem(:,[3,4]); elem(:,[4,1])];
end
totalEdge = sort(allEdge,2);
[edge,~,totalJ] = unique(totalEdge,'rows');
N = size(node,1); NT = size(elem,1); NE = size(edge,1); 
nc = size(elem,2);
elem2edge = reshape(totalJ,NT,nc);

%% Add new nodes: middle points of all edges
node(N+1:N+NE,:) = (node(edge(:,1),:)+node(edge(:,2),:))/2;
if size(elem,2)==4
    x = (node(elem(:,1),1) + node(elem(:,2),1))/2;
    y = (node(elem(:,1),2) + node(elem(:,4),2))/2;
    node(N+NE+(1:NT),:) = [x,y];
end

%% Refine each triangle into four triangles as follows
if size(elem,2)==3    
    % 3
    % | \
    % 5- 4
    % |\ |\
    % 1- 6- 2
    t = 1:NT; p = zeros(NT,6);
    p(:,1:3) = elem;
    p(:,4:6) = elem2edge + N;
    elem(t,:) = p(t,[1,6,5]); 
    elem(NT+t,:) = p(t,[6,2,4]);
    elem(2*NT+t,:) = p(t,[5,4,3]);
    elem(3*NT+t,:) = p(t,[4,5,6]);
end

%% Refine each square into four squares as follows
if size(elem,2)==4    
    % 4 - 7 -  3
    % |   |    |
    % 8-  9  - 6
    % |   |    |
    % 1-  5  - 2
    t = 1:NT; p = zeros(NT,9);
    p(:,1:4) = elem;
    p(:,5:8) = elem2edge + N;
    p(:,9) = N+NE+(1:NT)';
    elem(t,:) = p(t,[1,5,9,8]);
    elem(NT+t,:) = p(t,[5,2,6,9]);
    elem(2*NT+t,:) = p(t,[8,9,7,4]);
    elem(3*NT+t,:) = p(t,[9,6,3,7]);
end
