function R = LoadLineProfiles(root,excl)
% depreciated
    if ~iscell(root)
        root = {root};
    end
    
    if nargin < 2
        excl = cell(size(root));
    end

    R = {};
    for j=1:length(root)
        [folder,subfolders] = GetFRAPSubFolders(root{j});
        for i=1:length(subfolders)
            mat_out_file = [folder subfolders{i} filesep 'line recovery.mat'];
            if exist(mat_out_file,'file') && ~any(strcmp(excl{j},subfolders{i}))
                R{end+1} = load(mat_out_file,'l1','l2','R1','R2','total');
                R{end}.folder = folder;
                R{end}.subfolder = subfolders{i};
            else
                disp(['Excluding: ' mat_out_file]);
            end
        end
    end