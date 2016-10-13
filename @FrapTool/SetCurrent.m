

function SetCurrent(obj)

    n = length(obj.data.after);
    obj.handles.image_scroll.Max = n;
    obj.handles.image_scroll.Value = 1;
    obj.handles.image_scroll.SliderStep = [1/n 1/n];

    d = obj.data;

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

    rec_h = obj.handles.recovery_ax;
    cla(rec_h);
    recovery = obj.GetRecovery();
    plot(rec_h,recovery);
    hold(rec_h,'on');
    xlabel(rec_h,'Time (frames)');
    ylabel(rec_h,'Intensity');

    recovery = obj.GetRecovery('stable');
    plot(rec_h,recovery);


end