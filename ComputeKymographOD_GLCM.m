function contrast = ComputeKymographOD_GLCM(r, im, lim, max_distance, n_points)
%
% Compute interpolated OD GLCM on a kypmograph im 
% r: points along distance axis of kymograph
% max_distance: maximum distance to compute OD GLCM
% n_points: number of points to interpolate OD GLCM

    if nargin < 4
        max_distance = 2.5;
    end
    if nargin < 5
        n_points = 50;
    end

    if nargin < 3
        lim = 2000;
    end

    dist = length(r);
    step = 10;
        
    r = r(1:step:dist);
    rout = linspace(0,max_distance,n_points);
        
    
    glcm = graycomatrix(im, 'Offset', [(1:step:dist)' zeros(length(r),1)], 'GrayLimits', [0 lim]);
    props = graycoprops(glcm, 'Contrast');

    contrast = props.Contrast;
    contrast = interp1(r,contrast,rout);
    
end