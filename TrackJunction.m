function p = TrackJunction(flow, line, use_spline, np)
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

    if nargin < 3
        use_spline = true;
    end
    if nargin < 4
        np = 50;
    end
    
    if length(line) == 1 
        use_spline = false;
    end
    
    if use_spline
        p = GetSplineImg(line,np);
    else
        p = line;
    end
            
    p = p.';

    p = repmat(p,[size(flow,3) 1]);
    
    for i=2:size(flow,3)

        pl = p(i-1,:);
        xi = round(real(pl));
        yi = round(imag(pl));

        xi = max(xi,1);
        yi = max(yi,1);
        xi = min(xi,size(flow,2));
        yi = min(yi,size(flow,1));

        ii = sub2ind(size(flow),yi,xi);
        flowi = flow(:,:,i);

        f = double(flowi(ii));

        pn = p(i-1,:) + f;

        if use_spline
            pn = GetSplineImg(pn,np,'linear');
        end
        
        p(i,:) = pn;

    end