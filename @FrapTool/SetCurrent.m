function SetCurrent(obj)

    d = obj.data;

    obj.handles.dt_edit.String = num2str(d.dt);
    obj.handles.pixel_size_edit.String = num2str(d.px_per_unit);

    n = length(d.after);
    obj.handles.image_scroll.Max = n;
    obj.handles.image_scroll.Value = 1;
    obj.handles.image_scroll.SliderStep = [1/n 1/n];

    ax = obj.handles.image_ax;

    cla(ax);
    obj.handles.image = imagesc(d.after{1},'Parent',ax,'HitTest','on');
    set(ax,'XTick',[],'YTick',[]);
    daspect(ax,[1 1 1]);

    if size(obj.data.roi) >= 1
        obj.selected_roi = 1;
    else
        obj.selected_roi = 0;
    end
    
    hold(ax,'on');
    obj.handles.display_frap_roi = plot(ax, nan, nan, 'b', 'HitTest', 'off');
    obj.handles.display_tracked_roi = plot(ax, nan, nan, 'r', 'HitTest', 'off');
    obj.handles.selected_tracked_roi = plot(ax, nan, nan, 'r', 'HitTest', 'off', 'LineWidth', 2);
    

    z = zeros(size(d.after{1}));
    obj.handles.mask_image = image(z,'AlphaData',z,'Parent',ax,'HitTest','off');


    % Get centre of roi and stabalise using optical flow
    for i=1:length(d.roi)
        d.roi(i) = d.roi(i).Track(obj.data.flow);
    end
    obj.data.roi = d.roi;

    obj.UpdateDisplay();
    obj.UpdateRecoveryCurves();

    obj.handles.mask_image.ButtonDownFcn = @(~,~) obj.DisplayMouseDown;
    obj.handles.mask_image.HitTest = 'on';

    
end