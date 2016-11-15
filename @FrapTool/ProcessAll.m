function ProcessAll(obj)

    default_file = [GetLastFolder(obj.fh) filesep 'recovery.csv'];
    [file, folder] = uiputfile('*.csv','Choose File Name',default_file);
    
    if file == 0
        return
    end
    
    file = [folder file];

    [path,name,ext] = fileparts(file);
    
    untracked_file = [path name '_untracked' ext];
    tracked_file = [path name '_tracked' ext];
    
    [~,t] = GetRecovery(obj);
        
    h = waitbar(0,'Processing...');
    
    headers = {'Time (s)'};
    recovery_untracked = t;
    recovery_tracked = t;
    
    for i=1:2 %length(obj.reader.groups)
        
        obj.SwitchDataset(i);
        
        sel = strcmp({obj.data.roi.type},'Bleached Region');
        ru = GetRecovery(obj,sel);
        [rt,ti] = GetRecovery(obj,sel,'stable');
                        
        hs = {obj.data.roi(sel).label};
        hs = strcat(obj.data.name, hs);
        
        recovery_untracked = [recovery_untracked ru];
        recovery_tracked = [recovery_tracked rt];
        headers = [headers hs];
        
        assert(length(ti) == length(t) && all(ti==t),'All files must have the same time points!');
                
        waitbar(i/length(obj.reader.groups),h);
        
    end
    
    delete(h);
    
    csvwrite_with_headers(tracked_file, recovery_tracked, headers);
    csvwrite_with_headers(untracked_file, recovery_untracked, headers);
        
end