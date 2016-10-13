function SwitchDataset(obj,i)

    if isempty(i)
        return
    end

    obj.current_index = i;
    obj.data = obj.reader.GetGroup(obj.reader.groups{i});

    options.use_drift_compensation = obj.handles.drift_compensation_popup.Value == 2;
    options.image_smoothing_kernel_width = getNumFromPopup(obj.handles.image_smoothing_popup);
    options.flow_smoothing_kernel_width = getNumFromPopup(obj.handles.flow_smoothing_popup);
    options.frame_binning = getNumFromPopup(obj.handles.frame_binning_popup);

    if options.use_drift_compensation
        FeedbackMessage('GarvanFrap','Performing drift compensation');
        obj.data.after = CompensateDrift(obj.data.after, options);
    end

    FeedbackMessage('GarvanFrap','Computing Optical Flow');
    obj.data.flow = ComputeOpticalFlow(obj.data.after,options);

    FeedbackMessage('GarvanFrap','Finished Loading');

    obj.junction_artist.SetDataset(obj.data.after{1},...
                                   obj.data.roi,...
                                   obj.reader.file,...
                                   obj.current_index);

    obj.UpdateKymographList();
    obj.SetCurrent();
end