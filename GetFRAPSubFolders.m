function [folder, subfolders] = GetFRAPSubFolders(root)
% GetFRAPSubFolders
%    Get the subfolders containing FRAP movies from a FRAP dataset
%    Data should be structured as described in README.txt

    root = [root filesep];

    % String we use to distingish FRAP folders 
    magic_string = 'FRAP*';

    
    % Get folder containing FRAP data
    folder = dir(root);
    folder = folder(3:end);
    sel = [folder.isdir];
    group_name = folder(sel).name;
    folder = [root group_name '\'];

    % Get FRAP subfolders from that
    subfolders = dir([folder magic_string]);
    sel = [subfolders.isdir];
    subfolders = subfolders(sel);
    subfolders = {subfolders.name};
end