function UpdateDisplay(obj)

    cur = round(obj.handles.image_scroll.Value);

    t = obj.data.dt * (cur-1);
    obj.handles.scroll_text.String = ['t = ' num2str(t,'%.2f') 's'];

    image1 = double(obj.data.images{1});

    cur_image = double(obj.data.images{cur});
    cur_image =  cur_image / prctile(image1(:),99);
    out_im = repmat(cur_image,[1 1 3]);
    out_im(out_im > 1) = 1;

    mask_im = zeros(size(cur_image));

    ndil = 4; % TODO

    cmap = [0 0 0
            1 0 0
            0 1 0
            0 0 1];

    jcns = obj.junction_artist.junctions;
    for i=1:length(jcns)
        tp = jcns(i).tracked_positions;
        if ~isempty(tp)
            [~,idx] = GetThickLine(size(cur_image),tp(cur,:),600,ndil); 
            mask_im(idx) = jcns(i).type;
        end
    end

    obj.handles.image.CData = out_im;

    obj.handles.mask_image.CData = ind2rgb(mask_im+1,cmap);
    obj.handles.mask_image.AlphaData = 0.8*(mask_im>0);

    recovery_sel = strcmp({obj.data.roi.type},'Bleached Region');

    [x,y] = obj.data.roi(recovery_sel).GetCoordsForPlot(cur);
    set(obj.handles.display_tracked_roi,'XData',x,'YData',y);

    [x,y] = obj.data.roi(recovery_sel).GetCoordsForPlot(1);
    set(obj.handles.display_frap_roi,'XData',x,'YData',y);

    if sum(~recovery_sel) > 0
        [x,y] = obj.data.roi(~recovery_sel).GetCoordsForPlot(1);
    else
        x = nan;
        y = nan;
    end
    set(obj.handles.pb_roi,'XData',x,'YData',y);


    if ~isempty(obj.selected_roi) && obj.selected_roi <= length(obj.data.roi)

        if strcmp(obj.data.roi(obj.selected_roi).type,'Bleached Region')
            idx = cur;
        else
            idx = 1;
        end
        [x,y] = obj.data.roi(obj.selected_roi).GetCoordsForPlot(idx);
        set(obj.handles.selected_tracked_roi,'XData',x,'YData',y);
    end

end