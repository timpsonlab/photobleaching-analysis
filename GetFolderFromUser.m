function folder = GetFolderFromUser()

    persistent last_folder
    
    if isempty(last_folder)
        if ~isempty(strfind(computer('arch'),'win'))
            last_folder = getenv('USERPROFILE');
        else
            last_folder = getenv('HOME');
        end
    end
    
    folder = uigetdir(last_folder);
    folder = [folder filesep];
    last_folder = folder;
    
end
