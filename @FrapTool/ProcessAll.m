function ProcessAll(obj)

    [file, folder] = uiputfile('*.csv','Choose File Name',[obj.last_folder filesep 'recovery.csv']);
    
    if file == 0
        return
    end
    
    file = [folder file];

    [path,name,ext] = fileparts(file);
    
    untracked_file = [path name '_untracked' ext];
    tracked_file = [path name '_tracked' ext];
    
    [~,t] = GetRecovery(obj);
    
    dat_tracked = table();
    dat_untracked = table();

    dat_tracked.T = t;
    dat_untracked.T = t;
    
    h = waitbar(0,'Processing...');
    
    for i=1:length(obj.reader.groups)
        
        obj.SwitchDataset(i);
        
        recovery_untracked = GetRecovery(obj);
        [recovery_tracked,ti] = GetRecovery(obj,'stable');

        assert(length(ti) == length(t) && all(ti==t),'All files must have the same time points!');
        
        dat_tracked.(obj.data.name) = recovery_tracked;
        dat_untracked.(obj.data.name) = recovery_untracked;            
        
        waitbar(i/length(obj.reader.groups),h);
        
    end

    delete(h);
    
    writetable(dat_tracked,tracked_file);
    writetable(dat_untracked,untracked_file);

end