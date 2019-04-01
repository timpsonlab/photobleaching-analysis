function [tau,mobile] = IcsAnalysis(kymograph,dt,tmax,ax)

%kymograph(:,6) = nan;

tmax_idx = round(tmax / dt);

ki = double(kymograph);

kim = nanmean(ki,1);
kif = ki - kim;
kif(~isfinite(kif)) = 0;


%r = normxcorr2(kif,kif);
t=((1:size(ki,2))-1)*dt;
%s=((1:size(ki,1))-1)*dx;

%rti = r(size(ki,1),size(ki,2):end);
%rti(1) = nan;


sz = size(kymograph);
[GtAvg,RawGt] = tics(reshape(ki,[sz(1) 1 sz(2)]),1);
rti = GtAvg(:,2);
rti(1) = nan;

[tau,g0,g_inf] = FitTemporalCorrelation(t(1:tmax_idx),rti(1:tmax_idx));

mobile = g0 / (g0 + g_inf);

tf = t(1:tmax_idx);
fit = g0./(1+(tf/tau)) + g_inf;

if nargin >= 4
    plot(ax,t,rti,'xr')
    hold(ax,'on');
    
    plot(ax,tf,fit,'k-','LineWidth',2);
    hold(ax,'off');
    set(ax,'TickDir','out','Box','off')
    xlabel(ax,'Time (s)');
    ylabel(ax,'Temporal Autocorrelation')
    
    str = {['D ~ ' num2str(1/tau,5) ' s'];['mobile : ' num2str(mobile,5)]};
    text(ax.XLim(2), ax.YLim(2), str, ... 
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
         'Parent',ax);

end

disp([tau mobile])