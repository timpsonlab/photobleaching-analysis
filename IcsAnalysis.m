function [model,tics_curve,fitted] = IcsAnalysis(kymograph,dt,options,ax)

    kymograph(:,6) = nan;

    tmax_idx = round(options.time_max / dt);
    tmax_idx = min(tmax_idx, size(kymograph,2));

    ki = double(kymograph);

    t=((1:size(ki,2))-1)*dt;

    tics_curve = tics(ki);
    tics_curve(1) = nan;

    t_sel = t(1:tmax_idx);
    tics_sel = tics_curve(1:tmax_idx);
    
    [model, fitted] = FitTemporalCorrelation(t_sel,tics_sel,options);
    
    if nargin >= 4
        plot(ax,t,tics_curve,'xr')
        hold(ax,'on');

        plot(ax,t_sel,fitted,'k-','LineWidth',2);
        hold(ax,'off');
        
        set(ax,'TickDir','out','Box','off')
        xlabel(ax,'Time (s)');
        ylabel(ax,'Temporal Autocorrelation')
        ylim(ax,[0 1.2*max(tics_curve)]);

        str = {['tau : ' num2str([model.tau_diffusion model.tau_flow],5) ' s'];
               ['mobile : ' num2str([model.mobile_diffusion model.mobile_flow],5)]
               ['correlation time : ' num2str(model.mean_tau) ' s']};

        text(ax.XLim(2), ax.YLim(2), str, ... 
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
             'Parent',ax);
    end


end