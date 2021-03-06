function fig = GraphSig_Overlay(G1,G2,linewide1,ls1,lc1,linewide2,ls2,lc2)
% Display a plot of the data in GraphSig object G1 overlaid on the graph of
% G2
%
% Input
%   G1          GraphSig object #1
%   G2          GraphSig object #2 (G2.W is a subset of G1.W)
%   linewide1   the width of the edges for graph #1
%   ls1         the LineSpec for the edges of graph #1
%   lc1         the color of the edges of graph #1
%   linewide2   the width of the edges for graph #1 \setminus graph #2
%   ls2         the LineSpec for the edges of graph #1 \setminus graph #2
%   lc2         the color of the edges of graph #1 \setminus graph #2
%
% Output
%    fig        a plot figure
%
%
%
% Copyright 2015 The Regents of the University of California
%
% Implemented by Jeff Irion (Adviser: Dr. Naoki Saito)



% only run this for graphs with coordinates in 1D, 2D, or 3D space
if G1.dim ~= 1 && G1.dim ~= 2 && G1.dim ~= 3
    fig = 0;
    return
end

% for the purpose of using gplot, convert 1D graphs to 2D graphs
if G1.dim == 1
    G1.dim = 2;
    G1.xy(:,2) = 0;
    G2.dim = 2;
    G2.xy(:,2) = 0;
end

% only run this for 1D signals
[~,fcols] = size(G2.f);
if fcols ~= 1
    return
end

% extract the plot specifications
[symmetric,graybar,gray255bar,copperbar,notitle,nocolorbar,~,CLim,cmin,cmax,ptsize,~,~,marker,verbatim,verbtext] = ExtractPlotSpecs(G2);
set(0, 'DefaultFigureVisible', 'on');

% specify parameters that aren't given as inputs
if ~exist('linewide1','var')
    linewide1 = 2;
end
if ~exist('linewide2','var')
    linewide2 = 1;
end
if ~exist('ls1','var')
    ls1 = '-';
end
if ~exist('ls2','var')
    ls2 = ':';
end
if ~exist('lc1','var')
    lc1 = 'k';
end
if ~exist('lc2','var')
    lc2 = 'c';
end


%% The Plot

% plot the edges of the original graph
fig = figure('visible','on');
gplot3(G1.W,G1.xy,'LineStyle',ls1,'Color',lc1,'LineWidth',linewide1);
hold on

% determine the node sizes (if using variable sizes)
if ~isscalar(ptsize)
    if CLim
        ptsize = ptsize(1) + ptsize(2)*abs(G2.f)/max(abs([cmin,cmax]));
    else
        ptsize = ptsize(1) + ptsize(2)*abs(G2.f)/max(abs(G2.f));
    end
end

% plot the nodes
if ptsize(1) ~= 0
    if G1.dim == 2
        if ischar(marker)
            scatter(G1.xy(:,1), G1.xy(:,2), ptsize, marker, 'filled');
        else
            scatter(G1.xy(:,1), G1.xy(:,2), ptsize, G2.f, 'filled');
        end
    else
        if ischar(marker)
            scatter3(G1.xy(:,1), G1.xy(:,2), G1.xy(:,3), ptsize, marker, 'filled');
        else
            scatter3(G1.xy(:,1), G1.xy(:,2), G1.xy(:,3), ptsize, G2.f, 'filled');
        end
    end
end

% plot the edges that are cut
gplot3(G1.W-G2.W,G2.xy,'LineStyle',ls2,'Color',lc2,'LineWidth',linewide2);

% title?
if ~isempty(G1.name) && ~notitle
    title(G1.name);
end

% colorbar?
if ~nocolorbar
    colorbar;
end

% symmetric?
if symmetric
    cmax = max(abs(G2.f));
    if cmax < 10*eps
        cmax = 1;
    end
    set(gca, 'CLim', [-cmax, cmax]);
end

% gray255?
if gray255bar
    colormap('gray');
    set(gca, 'CLim', [0, 255]);

% gray?
elseif graybar
    colormap('gray');

% copper?
elseif copperbar
    colormap('copper');
    
% default?
else
    colormap('jet');
end

% custom dynamic display range?
if CLim
    set(gca, 'CLim', [cmin, cmax]);
end

% verbatim?
if verbatim
    eval(verbtext);
end


set(gcf,'color','w');



end