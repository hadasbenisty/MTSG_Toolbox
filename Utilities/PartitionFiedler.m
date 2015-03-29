function [pm,v] = PartitionFiedler(W,~,v,val)
% Given a weight matrix 'W', generate a Laplacian matrix and partition it 
% according to the Fiedler vector.  
%
% Inputs
%   W           the edge weight matrix
%   ~           if a 2nd input argument is given, use L_rw
%   v           the Fiedler vector
%   val         lambda_1
%
% Outputs
%   pm          a vector of 1's and -1's
%   v           the Fiedler vector
%
%
%
% Copyright 2015 The Regents of the University of California
%
% Implemented by Jeff Irion (Adviser: Dr. Naoki Saito)



%% Preliminaries

N = length(W);
eigs_flag = 0;

sigma = eps;
cutoff = 128; % this value could be changed...


%% handle the case when there are 2 nodes
if N == 2
    pm = [1;-1];
    v = pm/sqrt(2);
    return
end


%% L (unnormalized)
if nargin == 1 || min(sum(W)) < 10^3*eps
    if N > cutoff
        opts.issym = 1;
        opts.v0 = ones(N,1)/sqrt(N);
        warning('error','MATLAB:nearlySingularMatrix');
        warning('error','MATLAB:eigs:SigmaNearExactEig');
        
        try
            [v,val,eigs_flag] = eigs(diag(sum(W))-W,2,sigma,opts);
        catch
            eigs_flag = 2;
        end
        
        if eigs_flag == 0
            [~,ind] = max(diag(val));
            v = v(:,ind);
            val = val(ind,ind);
        end
    end
    if N <= cutoff || eigs_flag ~= 0
        %%% Fiedler vector via svd
        [v,val,~] = svd(full(diag(sum(W))-W));
        v = v(:,end-1);
        val = val(end-1,end-1);
    end
    
    
%% L_rw
elseif nargin == 2 || nargin == 3
    if N > cutoff
        opts.issym = 1;
        opts.v0 = ones(N,1)/sqrt(N);
        warning('error','MATLAB:nearlySingularMatrix');
        warning('error','MATLAB:eigs:SigmaNearExactEig');
        
        try
            [v,val,eigs_flag] = eigs(diag(sum(W))-W,diag(sum(W)),2,sigma,opts);
        catch
            eigs_flag = 2;
        end
        
        if eigs_flag == 0
            [~,ind] = max(diag(val));
            v = v(:,ind);
            v = (full(sum(W,2)).^(-0.5)) .* v;
            val = val(ind,ind);
        end
    end
    if N <= cutoff || eigs_flag ~= 0
        %%% Fiedler vector via svd
        [v,val,~] = svd( full( bsxfun(@times, bsxfun(@times, full(sum(W,2)).^(-0.5), diag(sum(W)) - W), (full(sum(W,1))).^(-0.5) ) ) );
        v = v(:,end-1);
        v = (full(sum(W,2)).^(-0.5)) .* v;
        val = val(end-1,end-1);
    end
end


%% Partitioning based on the Fiedler vector

% define a tolerance
tol = 10^3*eps;

% set the first nonzero element to be positive
row = 1;
while abs(v(row)) < tol && row < N
    row = row + 1;
end

if v(row) < 0
    v = -v;
end

% assign each point to either region 1 or region -1 in such a way that
% neither region is empty

if sum(v >= tol) > sum(v <= -tol) % more (+) than (-) entries
    pm = 2*(v >= tol) - 1;
else
    pm = 2*(v <= -tol) - 1;
end

% make sure the first point is assigned to region 1 (not -1)
if pm(1) < 0
    pm = -pm;
end
    


%% TROUBLESHOOTING
if sum(pm < 0) == 0 || sum(pm > 0) == 0 || sum(abs(pm)) < N

    % Case 1: it is not connected
    if val < tol
        pm = 2*(abs(v) > tol) - 1;
        while sum(pm < 0) == 0 || sum(pm > 0) == 0
            tol = 10*tol;
            pm = 2*(abs(v) > tol) - 1;
            if tol > 1
                pm(1:ceil(N/2)) = 1;
                pm(ceil(N/2)+1:N) = -1;
            end
        end

    % Case 2: it is connected
    else
        pm = 2*(v >= mean(v)) - 1;

        if sum(abs(pm)) < N
            % assign the near-zero points based on the values of v at their
            % neighbor nodes
            pm0 = (1:N)';
            pm0 = pm0(pm == 0);
            pm(pm0) = (W(pm0,:)*v > tol) - (W(pm0,:)*v < -tol);

            % assign any remaining zeros to the group with fewer members
            pm(pm == 0) = (sum(pm > 0) - sum(pm < 0)) >= 0;
        end
    end

    % if one region has no points
    if sum(pm < 0) == 0 || sum(pm > 0) == 0
        pm(1:ceil(N/2)) = 1;
        pm(ceil(N/2)+1:N) = -1;
    end
    
end


%% Wrap-up

% make sure that the 1 region has more points than the -1 region
if sum(pm < 0) > sum(pm > 0)
    pm = -pm;
    v = -v;
end

% make sure that the first point is assigned as a 1
if pm(1) < 0
    pm = -pm;
end


end