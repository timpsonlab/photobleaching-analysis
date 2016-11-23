function SetCurrent(obj)

    d = obj.data;

    obj.handles.dt_edit.String = num2str(d.dt);
    obj.handles.pixel_size_edit.String = num2str(d.units_per_px);

    n = length(d.images);
    obj.handles.image_scroll.Max = n;
    obj.handles.image_scroll.Value = 1;
    obj.handles.image_scroll.SliderStep = [1/n 1/n];

    ax = obj.handles.image_ax;

    cla(ax);
    obj.handles.image = imagesc(d.images{1},'Parent',ax,'HitTest','on');
    set(ax,'XTick',[],'YTick',[]);
    daspect(ax,[1 1 1]);
    
    hold(ax,'on');
    obj.handles.display_frap_roi = plot(ax, nan, nan, 'b', 'HitTest', 'off');
    obj.handles.display_tracked_roi = plot(ax, nan, nan, 'r', 'HitTest', 'off');
    obj.handles.selected_tracked_roi = plot(ax, nan, nan, 'r', 'HitTest', 'off', 'LineWidth', 2);
    obj.handles.pb_roi =  plot(ax, nan, nan, 'g', 'HitTest', 'off', 'LineWidth', 1);

    z = zeros(size(d.images{1}));
    obj.handles.mask_image = image(z,'AlphaData',z,'Parent',ax,'HitTest','off');


    % Get centre of roi and stabalise using optical flow
    for i=1:length(obj.data.roi)
        obj.data.roi(i) = obj.data.roi(i).Compute(obj.data);
    end
    
    if size(obj.data.roi) >= 1
        sel_roi = 1;
    else
        sel_roi = [];
    end
    
    obj.SetRoiSelection('roi',sel_roi);

    obj.UpdateDisplay();
    obj.UpdateRecoveryCurves();
    obj.UpdateKymographList();

    obj.handles.mask_image.ButtonDownFcn = @(~,~) obj.DisplayMouseDown;
    obj.handles.mask_image.HitTest = 'on';

    
end