function [px,py] = TrackJunction(flow, line_x, line_y, use_spline, np)
% TrackJunction
%    Uses pre-computed optical flow matrix 'flow' to track a junction
%    defined by the starting points line_x and line_y. Optionally use
%    spline interpolation to get and maintain equally spaced points along
%    the junction. 
%
%    Can be used to track a single point. 
%
%    flow: optical flow matrix
%    line_x: x coordinates of contiguous points along the junction
%    line_y: corresponding y coordinates of points along the junction
%    use_spline: use spline interpolation to obtain equally spaced points
%       along the junction 
%    np: number of points to use along spline


    FeedbackMessage('GarvanFrap','   Tracking Junction...');


    if nargin < 4
        use_spline = true;
    end
    if nargin < 5
        np = 10;
    end
    
    if length(line_x) == 1 
        use_spline = false;
    end
    
    if use_spline
        [px,py] = GetSpline(line_x,line_y,np);
    else
        px = line_x;
        py = line_y;
    end
        
    px = px';
    py = py';
    
    for i=2:size(flow,3)

        xi = round(px(i-1,:));
        yi = round(py(i-1,:));

        xi = max(xi,1);
        yi = max(yi,1);
        xi = min(xi,size(flow,2));
        yi = min(yi,size(flow,1));

        ii = sub2ind(size(flow),yi,xi,repmat(i,size(yi)));

        f = flow(ii);

        xn = px(i-1,:) + real(f);
        yn = py(i-1,:) + imag(f); 

        if use_spline
            [pxn,pyn] = GetSpline(xn,yn,np);
        else
            pxn = xn;
            pyn = yn;
        end
        
        px(i,:) = pxn;
        py(i,:) = pyn;

    end