function ProcessAll(obj)

    default_file = [GetLastFolder(obj.fh) filesep 'recovery.csv'];
    [file, folder] = uiputfile('*.csv','Choose File Name',default_file);
    
    if file == 0
        return
    end
    
    stored_load_option = obj.handles.load_option_popup.Value;
    obj.handles.load_option_popup.Value = 1; % Load all data;
    
    file = [folder file];

    [path,name,ext] = fileparts(file);
    
    untracked_file = [path filesep name '_untracked_regions' ext];
    tracked_file = [path filesep name '_tracked_regions' ext];

    junction_untracked_file = [path filesep name '_untracked_junctions' ext];
    junction_tracked_file = [path filesep name '_tracked_junctions' ext];

    [~,t] = GetRecovery(obj);
        
    h = waitbar(0,'Processing...');
    
    headers = {'Time (s)'};
    recovery_untracked = t;
    recovery_tracked = t;
    
    junction_headers = {'Time (s)'};
    junction_recovery_untracked = t;
    junction_recovery_tracked = t;
    
    for i=1:length(obj.reader.groups)
        
        obj.SwitchDataset(i);
        name = [strtrim(obj.data.name) '_'];
        
        %== Get bleach region recoveries

        sel = strcmp({obj.data.roi.type},'Bleached Region');
        ru = GetRecovery(obj,sel);
        [rt,ti] = GetRecovery(obj,sel,'stable');
                        
        hs = {obj.data.roi(sel).label};
        hs = strcat(obj.data.name, hs);
        
        if (length(ti) == length(t) && all(ti==t))        
            recovery_untracked = [recovery_untracked ru];
            recovery_tracked = [recovery_tracked rt];
            headers = [headers hs];
            
            [jrt, jru, jhs] = GetAllJunctionRecoveries(obj);

            junction_recovery_untracked = [junction_recovery_untracked jru];
            junction_recovery_tracked = [junction_recovery_tracked jrt];
            junction_headers = [junction_headers jhs];
            
        else
            warning(['Dataset ' obj.data.name 'had inconsistent timepoints, excluding results']);
        end
        
        %== Get junction recoveries
        
        
        waitbar(i/length(obj.reader.groups),h);
        
    end
    
    delete(h);
    
    csvwrite_with_headers(tracked_file, recovery_tracked, headers);
    csvwrite_with_headers(untracked_file, recovery_untracked, headers);

    csvwrite_with_headers(junction_tracked_file, junction_recovery_tracked, junction_headers);
    csvwrite_with_headers(junction_untracked_file, junction_recovery_untracked, junction_headers);

    obj.handles.load_option_popup.Value = stored_load_option;

end