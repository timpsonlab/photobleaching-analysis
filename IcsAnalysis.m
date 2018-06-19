function [tau,mobile,C] = IcsAnalysis(kymograph,dt,tmax,ax)

tmax_idx = round(tmax / dt);

ki = double(kymograph);

kim = nanmean(ki,1);

kif = ki - kim;

kif(~isfinite(kif)) = 0;


r = normxcorr2(kif,kif);
t=((1:size(ki,2))-1)*dt;
%s=((1:size(ki,1))-1)*dx;

rti = r(size(ki,1),size(ki,2):end);
rti(1) = nan;


[tau,mobile,C] = FitTemporalCorrelation(t(1:tmax_idx),rti(1:tmax_idx));

tf = t(1:tmax_idx);
fit = mobile./(1+(tf/tau)) + C;

if nargin >= 4
    plot(ax,t,rti,'xr')
    hold(ax,'on');
    
    plot(ax,tf,fit,'k-','LineWidth',2);
    hold(ax,'off');
    set(ax,'TickDir','out','Box','off')
    xlabel(ax,'Time (s)');
    ylabel(ax,'Temporal Autocorrelation')
    
    str = {['\tau : ' num2str(tau,5) ' s'];['IF : ' num2str(1-mobile,5)]};
    text(ax.XLim(2), ax.YLim(2), str, ... 
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
         'Parent',ax);

end


disp([tau mobile])