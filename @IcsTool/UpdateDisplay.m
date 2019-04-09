function UpdateDisplay(obj)

    cur = obj.handles.files_list.Value;
    
    if isempty(cur)
        return;
    end
    
    cur = cur(1);
    kymograph = obj.GetKymograph(cur);
    
    ki = kymograph.kymograph;
    ri = (0:size(ki,1)-1) * kymograph.spatial_units_per_pixel;
    ti = (0:size(ki,2)-1) * kymograph.temporal_units_per_pixel;
    
    
    ax = obj.handles.image_ax;
    imagesc(ti,ri,ki,'Parent',ax);
    ax.XLabel.String = 'Time (s)';
    ax.YLabel.String = 'Distance (\mum)';
    ax.Title.String = 'Junction Kymograph';
    ax.YLim = [min(ri) max(ri)];
    ax.XLim = [min(ti) max(ti)];
    TightAxes(ax);
    
    options = obj.GetOptions();
    
    IcsAnalysis(ki, kymograph.temporal_units_per_pixel, options, obj.handles.ics_ax);
    
    ax = obj.handles.glcm_ax;
    [contrast,r_contrast] = ComputeKymographOD_GLCM(ri, ki, options);
    plot(ax,r_contrast,contrast,'x');
    ylim(ax,[0 1])
    set(ax,'TickDir','out','Box','off')
    xlabel(ax,'Distance (\mum)');
    ylabel(ax,'Contrast')
    
end