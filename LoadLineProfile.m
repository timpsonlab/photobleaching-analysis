function R = LoadLineProfile(folder, subfolder)
    mat_out_file = [folder subfolder filesep 'line recovery.mat'];
    if exist(mat_out_file,'file')
        R = load(mat_out_file);
        R.folder = folder;
        R.subfolder = subfolder;
    else
        R = struct();
        FeedbackMessage('GarvanFrap',['Could not load: ' folder subfolder])
    end