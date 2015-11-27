function ProcessFRAPFolders(root)
    
    if nargin < 1
        root = GetFolderFromUser();
    end

    folders = GetFoldersFromFolder(root);
%{
    for i=1:length(folders)   
        ProcessFRAP([root filesep folders{i}])
    end
%}
    AssembleCurves(root, folders);
    
end