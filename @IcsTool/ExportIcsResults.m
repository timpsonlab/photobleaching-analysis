function ExportIcsResults(obj)

    [export_file,path] = uiputfile('*.xlsx','Choose Filename', [GetLastFolder(obj.fh) 'ICS.xlsx']);
    if export_file == 0
        return;
    end

    options = obj.GetOptions();
    
    for i=1:length(obj.kymographs)
        kymograph = obj.GetKymograph(i);
        ki = kymograph.kymograph;
            
        ti = (0:size(ki,2)-1) * kymograph.temporal_units_per_pixel;
        ri = (0:size(ki,1)-1) * kymograph.spatial_units_per_pixel;
      
        [contrast(:,i),r_contrast(:,1)] = ComputeKymographOD_GLCM(ri, ki, options);
        [model(i),tics(:,i)] = IcsAnalysis(ki, kymograph.temporal_units_per_pixel, options);
    end
    
    names = {obj.kymographs.name};
    
    summary_table = struct2table(model,'RowNames',names);
    writetable(summary_table,[path export_file],'Sheet','Summary','WriteRowNames',true);
    
    tics = num2cell([ti' tics]);
    tics = [[{'Time (s)'} names]; tics];    
    xlswrite([path export_file],tics,'TICS');

    contrast = num2cell([r_contrast contrast]);
    contrast = [[{'Distance (um)'} names]; contrast];    
    xlswrite([path export_file],contrast,'OD-GLCM Contrast');

    RemoveSheet123([path export_file]);
    
end