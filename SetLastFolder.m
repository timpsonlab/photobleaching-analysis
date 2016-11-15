function last_folder = SetLastFolder(fh,last_folder)
    if ischar(last_folder)
        fh.UserData.last_folder = last_folder;
        setpref('FrapTool','last_folder',last_folder);
    end
end
