function [contrast,rout] = ComputeKymographOD_GLCM(r, im, options)
%
% Compute interpolated OD GLCM on a kypmograph im 
% r: points along distance axis of kymograph
% max_distance: maximum distance to compute OD GLCM
% n_points: number of points to interpolate OD GLCM

    if nargin < 3
        options = struct();
    end

    if ~isfield(options,'max_distance')
        options.max_distance = 2.5;
    end
    if ~isfield(options,'n_points')
        options.n_points = 100;
    end

    if ~isfield(options,'glcm_lim')
        options.glcm_lim = 2000;
    end

    dist = length(r);
    step = 1;
        
    r = r(1:step:dist);
    rout = linspace(0,options.max_distance,options.n_points);
        
    im(~isfinite(im)) = 0;
    glcm = graycomatrix(im, 'Offset', [(1:step:dist)' zeros(length(r),1)], 'GrayLimits', [0 options.glcm_lim]);
    props = graycoprops(glcm, 'Contrast');

    contrast = props.Contrast;
    contrast = interp1(r,contrast,rout);
    
end