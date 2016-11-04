

function SetCurrent(obj)

    d = obj.data;

    obj.handles.dt_edit.String = num2str(d.dt);
    obj.handles.pixel_size_edit.String = num2str(d.px_per_unit);

    n = length(d.after);
    obj.handles.image_scroll.Max = n;
    obj.handles.image_scroll.Value = 1;
    obj.handles.image_scroll.SliderStep = [1/n 1/n];


    ax = [obj.handles.image_ax];
    image_h = {'image'};
    roi_h = {'image_frap_roi'};

    [roi_x,roi_y] = GetCoordsFromRoi(d.roi);
    for i=1:length(ax)
        cla(ax(i));
        obj.handles.(image_h{i}) = imagesc(d.after{1},'Parent',ax(i));
        set(ax(i),'XTick',[],'YTick',[]);
        daspect(ax(i),[1 1 1]);

        hold(ax(i),'on');
        obj.handles.(roi_h{i}) = plot(ax(i), roi_x, roi_y, 'g', 'HitTest', 'off');
    end

    obj.handles.display_tracked_roi = plot(obj.handles.image_ax, roi_x, roi_y, 'r', 'HitTest', 'off');

    z = zeros(size(d.after{1}));
    obj.handles.mask_image = image(z,'AlphaData',z,'Parent',obj.handles.image_ax);


    % Get centre of roi and stabalise using optical flow
    roi = d.roi.x + 1i * d.roi.y;
    p = mean(roi);
    obj.tracked_roi_centre = TrackJunction(obj.data.flow,p) - p;


    obj.UpdateDisplay();
    obj.UpdateRecoveryCurves();
   

end