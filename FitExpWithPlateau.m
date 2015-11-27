function [fitresult, gof] = FitExpWithPlateau(x, y)
% FitExpWithPlateau
%  Fit an exponential decay with a plateau.
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.

[xData, yData] = prepareCurveData( x, y );

% Starting points
plateau = 0.15;
Y0 = yData(1);
a = Y0 - plateau;
k = 0.15;

% Set up fittype and options.
ft = fittype( 'a*exp(-k*x)+plateau', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [0 0 0];
opts.StartPoint = [a k plateau];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
