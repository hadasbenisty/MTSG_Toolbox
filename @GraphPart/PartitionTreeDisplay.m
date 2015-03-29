function [W,xy,f] = PartitionTreeDisplay(GP)
% Display a partitioning tree for the recursive partitioning
%
% Input
%   GP      a GraphPart object
%
% Output
%   W       the weight matrix for the partition tree
%   xy      the (x,y) coordinates for the partition tree regions
%   f       the number of nodes in each partition tree region
%
%
%
% Copyright 2015 The Regents of the University of California
%
% Implemented by Jeff Irion (Adviser: Dr. Naoki Saito)



% constants
[N, jmax] = size(GP.rs);
N = N-1;

% the total number of folders
M = nnz(GP.rs)-jmax;

% allocate space for the weight matrix, the spatial coordinates of the
% nodes, and a vector indicating how many nodes are in each region
W = sparse(M,M);
xy = zeros(M,2);
f = zeros(M,1);


% the current index for the region on the coarser level in W, xy, and f
ind1 = 1;

for j = 1:jmax
    % compute the number of regions on the coarser level
    regioncount1 = nnz(GP.rs(:,j))-1;
    
    % update ind2 = the current index of the region on the finer level
    ind2 = ind1+regioncount1;
    r2 = 1;
    
    % cycle through the regions on the coarser level
    for r1 = 1:regioncount1
        % assign an xy coordinate to the current region
        xy(ind1,1) = mean(GP.rs(r1,j):(GP.rs(r1+1,j)-1));
        xy(ind1,2) = jmax-j;
        
        % store the number of nodes in the current region in f
        f(ind1) = GP.rs(r1+1,j)-GP.rs(r1,j);
        
        if j < jmax
            % the subregions: GP.rs(r2,j+1), GP.rs(r2+1,j+1), ...
            while GP.rs(r2,j+1) < GP.rs(r1+1,j)
                % add a weight between the region and its subregion
                W(ind1,ind2) = 1;
                W(ind2,ind1) = 1;
                
                % step the subregion and ind2 counters
                r2 = r2+1;
                ind2 = ind2+1;
            end
        end
        ind1 = ind1+1;
    end
end

gplot(W,xy);
hold on
xlim([0 N+1]);
if N > 100
    markersize = round(10^4/N);
else
    markersize = 100;
end
scatter((1:N)',zeros(N,1),markersize,GP.ind,'s','filled');


end