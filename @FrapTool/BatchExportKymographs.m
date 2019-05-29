function BatchExportKymographs(obj)

    root = uigetdir(GetLastFolder(obj.fh),'Choose Folder');
    root = [root filesep];
    
    folders = GetAllSubfolders(root,2);
    folders = strcat(folders,['merged' filesep]);

    disp('Folders to process:')
    disp(folders');
    
    for i=1:length(folders)

        files = dir([folders{i} '*.ome.tif']);
        files = {files.name};

        for j=1:length(files)
            obj.LoadData([folders{i} files{j}]);

            kymograph_folder = [folders{i} 'KymographsAuto'];
            mkdir(kymograph_folder);
            obj.ExportKymographs(kymograph_folder)
        end
    end