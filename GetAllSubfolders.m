function subfolders = GetAllSubfolders(folders, depth)

    if ~iscell(folders)
        folders = {folders};
    end

    subfolders = {};
    for i=1:length(folders)
        s = dir(folders{i});
        s = s([s.isdir]);
        s = {s.name};
        s = s(3:end); 
        s = strcat(folders{i}, s, filesep);
        subfolders = [subfolders s];
    end
    
    if depth > 1
        subfolders = GetAllSubfolders(subfolders, depth-1);
    end
    