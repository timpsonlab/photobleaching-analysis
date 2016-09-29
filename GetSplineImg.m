function P = GetSplineImg(p, n, method)
% GetSpline Get evenly spaced points along spline
%    
%    Uses interparc to generate evenly spaced points along a spline 
%    n: number of points
%    method: interpolation method (see interparc for options)
%
%    See also interparc

    if nargin < 2
        n = 50;
    end
    if nargin < 3
        method = 'spline';
    end

    pt = interparc(n,real(p),imag(p),method);
    P = pt(:,1) + 1i  * pt(:,2);
end