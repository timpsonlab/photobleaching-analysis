function ExportIcsResults(obj)

    [export_file,path] = uiputfile('*.csv','Choose Filename', [GetLastFolder(obj.fh) 'ICS.csv']);
    if export_file == 0
        return;
    end

    t_max = str2double(obj.handles.max_time_edit.String);
    
    for i=1:length(obj.kymographs)
        k = obj.kymographs(i);
        [tau(i),mobile(i),C(i)] = IcsAnalysis(k.data,k.temporal_units_per_pixel,t_max);
    end
    
    names = {obj.kymographs.name};
    
    t = table(tau', 1-mobile', C','VariableNames',{'tau','IF','C'},'RowNames',names);
    writetable(t,[path filesep export_file],'WriteRowNames',true);

end