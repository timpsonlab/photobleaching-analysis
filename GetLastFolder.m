function last_folder = GetLastFolder(fh)
    if ~isstruct(fh.UserData)
        fh.UserData = struct('last_folder','');
    elseif ~isfield(fh.UserData,'last_folder')
        fh.UserData.last_folder = '';
    end
    last_folder = fh.UserData.last_folder;
end
