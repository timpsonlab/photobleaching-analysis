function [X,Y] = GetSpline(x, y, n, method)
% GetSpline Get evenly spaced points along spline
%    
%    Uses interparc to generate evenly spaced points along a spline 
%    n: number of points
%    method: interpolation method (see interparc for options)
%
%    See also interparc

    if nargin < 3
        n = 50;
    end
    if nargin < 4
        method = 'spline';
    end

    pt = interparc(n,x,y,method);
    X = pt(:,1);
    Y = pt(:,2);
end