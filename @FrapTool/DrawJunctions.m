function DrawJunctions(obj)
% DrawJunctions Allow user to draw up to eight junctions on a FRAP movie.
%   frap should either be:  
%       * A FRAP data structure
%       * A single image 
%   A file 'points.mat' containing the saved points is saved in path
%   If the points file exists, it is read in and displayed.
%
%   To draw junctions: 
%       1. Press the number of the junction to draw (1-8)
%       2. Click on a number of *contiguous* points along the junction. The
%          spacing of the points is not important
%
%   To clear a junction:
%       1. Press the number of the junction to clear (1-8)
%       2. Press 'd'

           
    colors = {'g', 'b', 'r', 'm', 'c', 'y', 'g', 'b'};
    
    if exist([path 'points.mat'],'file')
        p = load([path 'points.mat'],'x','y');
        x = p.x;
        y = p.y;
    else
        for i=1:8
            x{i} = [];
            y{i} = [];
        end
    end
    
    for i=(length(x)+1):8
        x{i} = [];
        y{i} = [];
    end
    
    for i=1:8
        if isempty(x{i})
            xl = 0;
            yl = 0;
        else
            xl = x{i};
            yl = y{i};
        end
        l(i) = line(xl,yl,'Marker','o','MarkerSize',7,'Color','k','LineStyle','-','MarkerFaceColor',colors{i});
    end
    
    cur_idx = 1;

    set(fh, 'Name', 'Press number of junction and click on points')
    set(fh, 'WindowButtonDownFcn', @MouseDown);
    set(fh, 'Pointer', 'crosshair', 'NumberTitle', 'Off');
    set(fh, 'KeyPressFcn', @KeyPress)

    uiwait(fh);
    
    function MouseDown(~,~)
        [x0,y0] = GetCurrentPoint();
        if length(x) < cur_idx
            x{cur_idx} = [];
            y{cur_idx} = [];
        end
        x{cur_idx} = [x{cur_idx} x0];
        y{cur_idx} = [y{cur_idx} y0];
        save([path 'points.mat'],'x','y');
        set(l(cur_idx),'XData',x{cur_idx},'YData',y{cur_idx})
    end

    function [x,y] = GetCurrentPoint()
        pt = get(ax, 'CurrentPoint');
        x = pt(1,1);
        y = pt(1,2); 
    end

    function KeyPress(~,evt)

        num = str2double(evt.Key);
        if ~isempty(num) && num >= 1 && num <= 8
            cur_idx = num;
        end
        
        if strcmp(evt.Key,'d')
           x{cur_idx} = [];
           y{cur_idx} = [];
           set(l(cur_idx),'XData',0,'YData',0);           
        end
        
    end
        
    
end