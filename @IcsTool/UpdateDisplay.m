function UpdateDisplay(obj)

    cur = obj.handles.files_list.Value;
    
    if isempty(cur)
        return;
    end
    
    cur = cur(1);
    t_max = str2double(obj.handles.max_time_edit.String);
    
    kymograph = obj.kymographs(cur);
    ki = kymograph.data;
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
    
    
    ax = obj.handles.fit_ax;
    IcsAnalysis(ki,kymograph.temporal_units_per_pixel,t_max, ax);
    
end