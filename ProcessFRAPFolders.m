function ProcessFRAPFolders(root)
    
    if nargin < 1
        root = GetFolderFromUser();
    end

    folders = GetFoldersFromFolder(root);

    for i=1:length(folders)   
        [folder, subfolders] = GetFRAPSubFolders([root folders{i}]);
        
        for j=1:length(subfolders)
            ComputeFRAPRecoveryWithStabalisation(folder,subfolders{j});
        end
    end
    
    AssembleCurves(root, folders);
    
end