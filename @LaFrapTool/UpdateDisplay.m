function UpdateDisplay(obj)

     [rc,ti_final,combined_kymograph,n] = obj.GenerateCombinedKymograph();

    cur = obj.handles.files_list.Value;
    if ~isempty(cur)
                
        ax = obj.handles.image_ax;
        imagesc(ti_final,rc,combined_kymograph,'Parent',ax);
        ax.XLabel.String = 'Time (s)';
        ax.YLabel.String = 'Distance (\mum)';
        ax.Title.String = 'Averaged Junction Kymograph';
        ax.YLim = [min(rc) max(rc)];
        ax.XLim = [min(ti_final) max(ti_final)];
        TightAxes(ax);
                
        k = combined_kymograph;
        sz = size(k);
        d = 10;
        k = reshape(k,[d sz(1)/d sz(2)]);
        k = squeeze(mean(k,1));
        
        r = rc(d/2:d:end);
                
        a = nan(size(ti_final));
        s = nan(size(ti_final));
        
        k_fit = nan(size(k));
        
        parfor j=(n+1):1:sz(2)
            
            kj = double(k(:,j)');
            sel = isfinite(kj);
                        
            [fit_result,kf] = FitGaussian(r(sel),kj(sel));
            
            kf1 = nan(size(kj));
            kf1(sel) = kf;
            k_fit(:,j) = kf1;
            
            a(j) = fit_result.a;
            s(j) = fit_result.s;
            
        end

        sel = isfinite(s);
        [~,stats] = robustfit(ti_final(sel),s(sel));
        
        [fitobj] = fit(ti_final(sel)',s(sel)','poly1','Weights',stats.w);
        
        s_fit = fitobj.p2 + ti_final * fitobj.p1;
        %{
        [p,S] = polyfit(ti_final(sel),s(sel),1);
        S.Rinv = inv(S.R);
        cov = (S.Rinv*S.Rinv')*S.normr^2/S.df;

        s_fit = polyval(p,ti_final);
        %}
        
        p_lim = predint(fitobj,ti_final,0.95,'functional','on');
        
        
        if obj.handles.include_outliers_popup.Value == 1
            s_sel = s(sel);
            max_y = 1.2 * max(s_sel(stats.w > 0.1));
        else
            max_y = 1.2 * max(s);
        end
        
        if obj.handles.spatial_display_popup.Value == 1
            k_plot = k;
        else
            k_plot = k_fit;
        end
                
        ax = obj.handles.profile_ax;
        ax.ColorOrder = cool(sz(2));
        cla(ax); hold(ax,'on');
        plot(ax,r,k_plot);
        ax.XLabel.String = 'Distance (\mum)';
        ax.YLabel.String = 'Intensity';
        ax.Title.String = 'Spatial profile with time';
        ax.YLim = [0 1.2];
        TightAxes(ax);

        
        ax = obj.handles.fit_ax;
        plot(ax,ti_final,s,'o','Color',[0.5 0.5 0.5]);
        hold(ax,'on');
        plot(ax,ti_final,s_fit,'k-');
        plot(ax,ti_final,p_lim,'r--');
        hold(ax,'off');
        ax.YLim = [0 max_y];
        ax.XLabel.String = 'Time (s)';
        ax.YLabel.String = 'Width (\mum)';
        ax.Title.String = 'Width of bleached region with time';
        TightAxes(obj.handles.fit_ax);
        %xlim([10 400]);
        
        D = fitobj.p1/4; % um^2/s
        ci = confint(fitobj,0.95);
        ci = ci(:,1) / 4;
        
        str = ['Diffusion Coeff: ' num2str(D,3) ' (' num2str(ci(1),3) ' - ' num2str(ci(2),3) ') \mum^2/s'];
        text(max(ti_final), 0, str, ... 
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom',...
             'Parent',ax);

        
    end
end