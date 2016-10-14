function ProcessAll(obj)

    [file, folder] = uiputfile('*.xls','Choose File Name',[obj.last_folder filesep 'recovery.xls']);
    
    if file == 0
        return
    end
    
    file = [folder file];

    rec = GetRecovery(obj);
    T = (0:length(rec)-1)';

    dat_tracked = table();
    dat_untracked = table();

    dat_tracked.T = T;
    dat_untracked.T = T;
    
    h = waitbar(0,'Processing...');
    
    for i=1:length(obj.reader.groups)
        
        obj.SwitchDataset(i);
        
        recovery_untracked = GetRecovery(obj);
        recovery_tracked = GetRecovery(obj,'stable');

        dat_tracked.(obj.data.name) = recovery_tracked;
        dat_untracked.(obj.data.name) = recovery_untracked;            
        
        waitbar(i/length(obj.reader.groups),h);
        
    end

    delete(h);
    
    writetable(dat_tracked,file,'Sheet','Tracked');
    writetable(dat_untracked,file,'Sheet','Untracked');
    DeleteDefaultExcelSheets(file);

end