function SwitchDataset(obj,i)

    if isempty(i)
        return
    end
   
    group = obj.reader.groups{i};
    
    n_channels = obj.reader.GetNumChannels(group);
    obj.handles.channel_popup.String = arrayfun(@num2str,1:n_channels,'UniformOutput',false);
    if obj.handles.channel_popup.Value > n_channels
        obj.handles.channel_popup.Value = 1;
    end
    
    options.load_first_only = obj.handles.load_option_popup.Value == 2;
    options.use_flow_compensation = obj.handles.flow_compensation_popup.Value == 2;
    options.use_drift_compensation = obj.handles.drift_compensation_popup.Value == 2;
    options.image_smoothing_kernel_width = getNumFromPopup(obj.handles.image_smoothing_popup);
    options.flow_smoothing_kernel_width = getNumFromPopup(obj.handles.flow_smoothing_popup);
    options.frame_binning = getNumFromPopup(obj.handles.frame_binning_popup);
    
    obj.current_index = i;

    MessageHandler.send('GarvanFrap','Reading Data...');
    obj.data = obj.reader.GetGroup(group,obj.handles.channel_popup.Value,options.load_first_only);

    if options.use_drift_compensation
        MessageHandler.send('GarvanFrap','Performing drift compensation...');
        obj.data.images = CompensateDrift(obj.data.images, options);
    end

    sel = (obj.data.n_prebleach_frames+1):length(obj.data.images);
    after_images = obj.data.images(sel);
    
    if options.use_flow_compensation && length(after_images) > 2
        MessageHandler.send('GarvanFrap','Computing optical flow...');
        obj.data.flow = ComputeOpticalFlow(after_images,options);
    
        % Set flow of initial frames to zero
        obj.data.flow = padarray(obj.data.flow,[0 0 obj.data.n_prebleach_frames],0,'pre');
    else
        obj.data.flow = zeros([size(obj.data.images{1}) length(obj.data.images)],'single');
    end
    
    MessageHandler.send('GarvanFrap','Finished Loading');

    obj.junction_artist.SetDataset(obj.data.images{1},...
                                   obj.data.roi,...
                                   obj.reader.file,...
                                   obj.current_index);
                               
    obj.TrackJunctions();

    %obj.handles.tab_panel.Selection = 1;

    obj.UpdateKymographList();
    obj.SetCurrent();
end