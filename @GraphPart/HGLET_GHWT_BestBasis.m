function [dvec,BS,trans] = HGLET_GHWT_BestBasis(dmatrixH,dmatrixHrw,dmatrixHsym,dmatrixG,GP,costfun,flatten)
% Select the best basis from several matrices of expansion coefficients
%
% Input
%   dmatrixH    the matrix of HGLET expansion coefficients ==> eigenvectors
%               of L
%   dmatrixHrw  the matrix of HGLET expansion coefficients ==> eigenvectors
%               of Lrw
%   dmatrixHsym the matrix of HGLET expansion coefficients ==> eigenvectors
%               of Lsym
%   dmatrixG    the matrix of GHWT expansion coefficients
%   GP          a GraphPart object
%   costfun     the cost functional to be used
%   flatten     the method for flattening vector-valued data to
%               scalar-valued data
%
% Output
%   dvec        the vector of expansion coefficients corresponding to the 
%               bestbasis
%   BS          a BasisSpec object which specifies the best-basis
%   trans       specifies which transform was used for that portion of the
%               signal: 
%                   00 = HGLET with L
%                   01 = HGLET with Lrw
%                   10 = HGLET with Lsym
%                   11 = GHWT
%
%
%
% Copyright 2015 The Regents of the University of California
%
% Implemented by Jeff Irion (Adviser: Dr. Naoki Saito)



% specify transform codes
transHsym = [ true,false];
transG    = [ true, true];
transHrw  = [false, true];
transH    = [false,false];

% the cost functional to be used
useMDL = false;
if ~exist('costfun','var')
    costfun = @(x) norm(x,0.1);
elseif isnumeric(costfun)
    costfun = @(x) norm(x,costfun);
elseif ischar(costfun) && strcmpi(costfun,'MDL')
    useMDL = true;
elseif ~isa(costfun,'function_handle')
    costfun = @(x) norm(x,0.1);
end

% constants and dmatrix cleanup
if ~isscalar(dmatrixHsym)
    [N,jmax,fcols] = size(dmatrixHsym);
    dmatrixHsym( abs(dmatrixHsym) < 10^2*eps ) = 0;
elseif ~isscalar(dmatrixG)
    [N,jmax,fcols] = size(dmatrixG);
    dmatrixG( abs(dmatrixG) < 10^2*eps ) = 0;
elseif ~isscalar(dmatrixHrw)
    [N,jmax,fcols] = size(dmatrixHrw);
    dmatrixHrw( abs(dmatrixHrw) < 10^2*eps ) = 0;
elseif ~isscalar(dmatrixH)
    [N,jmax,fcols] = size(dmatrixH);
    dmatrixH( abs(dmatrixH) < 10^2*eps ) = 0;
else
    fprintf('\n\nNo coefficient matrices provided.  Exiting now.\n\n');
    return
end
    
% "flatten" dmatrix
if fcols > 1
    if ~exist('flatten','var')
        flatten = 1;
    end
    if ~isscalar(dmatrixHsym)
        dmatrix0Hsym = dmatrixHsym;
        dmatrixHsym = dmatrix_flatten(dmatrixHsym,flatten);
    end
    if ~isscalar(dmatrixG)
        dmatrix0G = dmatrixG;
        dmatrixG = dmatrix_flatten(dmatrixG,flatten);
    end
    if ~isscalar(dmatrixHrw)
        dmatrix0Hrw = dmatrixHrw;
        dmatrixHrw = dmatrix_flatten(dmatrixHrw,flatten);
    end
    if ~isscalar(dmatrixH)
        dmatrix0H = dmatrixH;
        dmatrixH = dmatrix_flatten(dmatrixH,flatten);
    end
end

% MDL stuff
if useMDL
    % compute the number of bits needed to store trans entries
    trans_cost = ceil(log2( ~isscalar(dmatrixHsym) + ~isscalar(dmatrixG) ...
        + ~isscalar(dmatrixHrw) + ~isscalar(dmatrixH)));
    
    % compute the number of bits needed to store levlist entries
    levlist_cost = 0*ceil(log2(jmax));
    
    % compute the number of bits needed to store levlengths entries
    % (equivalently, to store regionstarts entries)
    levlens_cost = ceil(log2(N));
    
    kmin = 1;
    kmax = 1 + ceil(0.5*log2(N));
    
    % define the cost functional
    costfun = @(x) MDL(x,kmin,kmax,levlist_cost,levlens_cost,trans_cost);
    
    % normalize the coefficients
    if ~isscalar(dmatrixHsym)
        dnorm = norm(dmatrixHsym(:,end),2)/sqrt(N);
        dmatrixHsym = dmatrixHsym/dnorm;
    end
    if ~isscalar(dmatrixG)
        dnorm = norm(dmatrixG(:,end),2)/sqrt(N);
        dmatrixG = dmatrixG/dnorm;
    end
    if ~isscalar(dmatrixHrw)
        dnorm = norm(dmatrixHrw(:,end),2)/sqrt(N);
        dmatrixHrw = dmatrixHrw/dnorm;
    end
    if ~isscalar(dmatrixH)
        dnorm = norm(dmatrixH(:,end),2)/sqrt(N);
        dmatrixH = dmatrixH/dnorm;
    end
end


%% Find the HGLET/GHWT best-basis

% allocate/initialize ==> order matters here
if ~isscalar(dmatrixHsym)
    dvec = dmatrixHsym(:,jmax);
    trans = repmat(transHsym,N,1);
end
if ~isscalar(dmatrixG)
    dvec = dmatrixG(:,jmax);
    trans = repmat(transG,N,1);
end
if ~isscalar(dmatrixHrw)
    dvec = dmatrixHrw(:,jmax);
    trans = repmat(transHrw,N,1);
end
if ~isscalar(dmatrixH)
    dvec = dmatrixH(:,jmax);
    trans = repmat(transH,N,1);
end
levlist = jmax*ones(N,1,'uint8');

% allocate a vector to store MDL costs
costs = zeros(N,1);
if useMDL
    for row = 1:N
        costs(row) = costfun(dvec(row));
    end
end

% set the tolerance
tol = 10^4*eps;

% perform the basis search
for j = jmax-1:-1:1
    regioncount = nnz(GP.rs(:,j))-1;
    for r = 1:regioncount
        indr = GP.rs(r,j):GP.rs(r+1,j)-1;
        %%%%% compute the cost of the current best basis
        if useMDL
            costBB = sum(costs(indr));
        else
            costBB = costfun(dvec(indr));
        end
            
        %%%%% compute the cost of the HGLET-Lsym coefficients
        if ~isscalar(dmatrixHsym)
            costNEW = costfun( dmatrixHsym(indr,j) );
            % change the best basis if the new cost is less expensive
            if costBB >= costNEW - tol
                [costBB, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixHsym(indr,j),j,transHsym);
            end
        end
        
        %%%%% compute the cost of the GHWT coefficients
        if ~isscalar(dmatrixG)
            if length(indr) == 1 || norm(dmatrixG(indr(2:end),j),1) / norm(dmatrixG(indr(1),1),1)  < 10^-3
                % specify as the default transform for a constant segment
                costNEW = -1;
                [costBB, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixG(indr,j),j,transG);
            else
                costNEW = costfun( dmatrixG(indr,j) );
                % change the best basis if the new cost is less expensive
                if costBB >= costNEW - tol
                    [costBB, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixG(indr,j),j,transG);
                end
            end
        end
        
        %%%%% compute the cost of the HGLET-Lrw coefficients
        if ~isscalar(dmatrixHrw)
            % specify as the default transform for a constant segment
            if length(indr) == 1 || norm(dmatrixHrw(indr(2:end),j),1) / norm(dmatrixHrw(indr(1),1),1)  < 10^-3
                costNEW = -1;
                [costBB, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixHrw(indr,j),j,transHrw);
            else
                costNEW = costfun( dmatrixHrw(indr,j) );
                % change the best basis if the new cost is less expensive
                if costBB >= costNEW - tol
                    [costBB, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixHrw(indr,j),j,transHrw);
                end
            end
        end
        
        %%%%% compute the cost of the HGLET-L coefficients
        if ~isscalar(dmatrixH)
            if length(indr) == 1 || norm(dmatrixH(indr(2:end),j),1) / norm(dmatrixH(indr(1),1),1)  < 10^-3
                % specify as the default transform for a constant segment
                [~, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixH(indr,j),j,transH);
            else
                costNEW = costfun( dmatrixH(indr,j) );
                % change the best basis if the new cost is less expensive
                if costBB >= costNEW - tol
                    [~, dvec(indr), levlist(indr), trans(indr,:), costs(indr)] = BBchange(costNEW,dmatrixH(indr,j),j,transH);
                end
            end
        end
    end
end

transfull = trans;
trans( levlist==0,: ) = [];
levlist( levlist==0 ) = [];

BS = BasisSpec(levlist,[],true,'HGLET-GHWT Best Basis');
BS = levlist2levlengths(GP,BS);


% if using MDL, rescale the coefficients
if useMDL && fcols == 1
    dvec = dvec*dnorm;
end


% if we flattened dmatrix, then "unflatten" the expansion coefficients
if fcols > 1
    % create vectors of coefficients (which are zero if the transform's coefficients were not included as function inputs)
    if ~isscalar(dmatrixH)
        dvecH = dmatrix2dvec(dmatrix0H,GP,BS);
    else
        dvecH = zeros(N,fcols);
    end
    if ~isscalar(dmatrixHrw)
        dvecHrw = dmatrix2dvec(dmatrix0Hrw,GP,BS);
    else
        dvecHrw = zeros(N,fcols);
    end
    if ~isscalar(dmatrixHsym)
        dvecHsym = dmatrix2dvec(dmatrix0Hsym,GP,BS);
    else
        dvecHsym = zeros(N,fcols);
    end
    if ~isscalar(dmatrixG)
        dvecG = dmatrix2dvec(dmatrix0G,GP,BS);
    else
        dvecG = zeros(N,fcols);
    end
    
    dvec = bsxfun(@times, dvecHsym,  transfull(:,1) .* ~transfull(:,2)) ...
            + bsxfun(@times, dvecG,  transfull(:,1) .*  transfull(:,2)) ...
          + bsxfun(@times, dvecHrw, ~transfull(:,1) .*  transfull(:,2)) ...
            + bsxfun(@times, dvecH, ~transfull(:,1) .* ~transfull(:,2));
end


end




function [costBB, dvec, levlist, trans, costs] = BBchange(costNEW, dvec, j, trans)
% Change to the new best basis

costBB = costNEW;

n = length(dvec);

levlist = zeros(n,1,'uint8');
levlist(1) = j;

trans = repmat(trans,n,1);

costs = zeros(n,1);
costs(1) = costNEW;
end