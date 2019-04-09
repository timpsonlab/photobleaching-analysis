function [tics] = tics(kymograph)

% July 10, 2003
% David Kolin
% Calculates time correlation function given 3D array of image series


kymograph = double(kymograph);
kmean = nanmean(kymograph,1);
kymograph = kymograph - nanmean(kymograph(:));

nt = size(kymograph,2);

tics = zeros(1,nt);

kymograph = kymograph ./ kmean;

parfor tau = 0:(nt-1)
   lagcorr = zeros(1,nt-tau); % preallocation   
   for pair=1:(nt-tau)
       corr = kymograph(:,pair).*kymograph(:,pair+tau);
       lagcorr(pair) = nanmean(corr);
   end
   tics(tau+1) = nanmean(lagcorr);
end

