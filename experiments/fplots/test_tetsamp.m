%% Test tetrahedron samples
[T,S,X,C] = tetrahedron_samples(50);
% S are points on the simplex
% X are points projected to the tetrahedron
% C helps project
%% 
smap = @(x) C*x(1:3, :) + T(:, 4)*ones(1, size(x, 2));

%% compute the function value for the volume
P = X; % points to plot
vnj = max(S);
thresh = 0.8;
P = X(:,vnj >thresh);
vnj = vnj(vnj > thresh);
clf; hold on;
scatter3(P(1,:), P(2,:), P(3,:), 25, vnj, 'filled');
h = trimesh([1 2 3; 1 2 4; 1 3 4; 2 3 4], T(1,:), T(2,:), T(3,:),[0,0,0,0]);
set(h,'FaceColor','none');
set(h,'EdgeColor','k');
%scatter3(P(1,:), P(2,:), P(3,:), 25, vnj, 'filled');
cmapsetup_large

%% Try a Delauney surface
DT = delaunay(P');
tetramesh(DT,P');

%% compute the function value for the volume
P = X; % points to plot
vnj = sum(smap(S).*smap(S));
thresh = 0.4;
P = X(:,vnj >thresh);
vnj = vnj(vnj > thresh);
clf; hold on;
scatter3(P(1,:), P(2,:), P(3,:), 25, vnj, 'filled');
h = trimesh([1 2 3; 1 2 4; 1 3 4; 2 3 4], T(1,:), T(2,:), T(3,:),[0,0,0,0]);
set(h,'FaceColor','none');
set(h,'EdgeColor','k');
axis off;
axis tight;
axis equal;
view([29,68]);
camzoom(1.5);
%%
camlight headlight;
lighting gouraud

scatter3(P(1,:), P(2,:), P(3,:), 25, vnj, 'filled');
cmapsetup_large

%% Try an isosurface
P = X; % points to plot
vnj = sum(smap(S).*smap(S));
%thresh = 0.4;
%P = X(:,vnj >thresh);
%vnj = vnj(vnj > thresh);
clf; hold on;

[xg,yg,zg] = meshgrid(-1 : 0.05 : 1);
% Create the interpolating object
F = TriScatteredInterp(P(1,:)',P(2,:)',P(3,:)', vnj');
% Do the interpolation
eg = F(xg,yg,zg);
% Now you can use isosurface with the gridded data
patch(isosurface(xg,yg,zg,eg>=thresh,thresh));
lighting gouraud
camlight

%% Try scatter with transparency
P = X; % points to plot
vnj = max(S);
thresh = 0.8;
P = X(:,vnj >thresh);
vnj = vnj(vnj > thresh);
clf; hold on;
hs = scatter3(P(1,:), P(2,:), P(3,:), 25, vnj);
h = trimesh([1 2 3; 1 2 4; 1 3 4; 2 3 4], T(1,:), T(2,:), T(3,:),[0,0,0,0]);
set(h,'FaceColor','none');
set(h,'EdgeColor','k');
%scatter3(P(1,:), P(2,:), P(3,:), 25, vnj, 'filled');
cmapsetup_large

%% Try using the volume visualization tool
amap = eg>=thresh;
vol3d('CData',eg,'XData',xg,'YData',yg,'ZData',zg,'Alpha',eg.^2,'texture','3D');
axis off;
alphamap('rampdown')
cmapsetup_large

%% Try using a Delauney triangulation and the trimesh option
DT = DelaneyTri(X');
%%
vnj = sum(smap(S).*smap(S));
trimesh(DT,X(1,:),X(2,:),X(3,:),X(1,:));

%%
[T,S,X,C] = tetrahedron_samples(3);
Xt = X';
Xt = flipud(Xt);
DT = DelaunayTri(Xt);
tetramesh(DT,'FaceColor','cyan');

%%

[T,S,X,C] = tetrahedron_samples(3);
vnj = sum(smap(S).*smap(S));
[~,p] = sort(vnj,'descend');
Xt = X(:,p)';
Dt = DelaunayTri(Xt);
tetramesh(Dt,'FaceColor','cyan');
