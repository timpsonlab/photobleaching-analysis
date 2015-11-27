function [folders,subfolders,root,labels] = GetFRAPDataset(dataset)

    if strcmp(dataset,'Zahra')
        subfolders = {{'ctrl pancreas'}, {'kras tumour'}, {'p53flox tumour'}, {'p53175 tumour'}, {'175 tumor+das'}};
        folders = repmat({{'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Zahra\Zahra data tif stacks\'}},[1 5]);
        root = 'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Zahra\Zahra data tif stacks\';
        labels = {'ctrl pancreas','kras tumour','p53flox tumour','p53175 tumour','175 tumor+das'};
        return;
    end

    switch dataset

        case 'Cell FLIP'
            
            root = 'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FLIP\';
            directories{1} = {'060915 vector DMSO', '071015 vector FLIP'};
            exclude{1} = {{},{'FRAP_004','FRAP_007'}};
            
            directories{2} = {'060915 175 DMSO','080915 175 DMSO', '071015 175 FLIP'};
            exclude{2} = {{'FRAP_006'},{'FRAP_005'},{'FRAP_000','FRAP_003','FRAP_004','FRAP_005'}};
                    
            labels = {'Vector','R175'};
            
        case 'Xeno FLIP'
            root = 'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\xenos\FLIP\';

            directories{1} = {'200915 18 vector', '240915 17 vector', '280915 20 vector'};
            exclude{1} = {{'FRAP_000','FRAP_005'},...
                          {'FRAP_003','FRAP_004','FRAP_005','FRAP_010'},...
                          {'FRAP_000','FRAP_001','FRAP_003','FRAP_004'}};

            directories{2} = {'190915 96 175', '220915 92 175', '260915 98 175'};
            exclude{2} = {{'FRAP_000','FRAP_002','FRAP_003','FRAP_004'},...
                          {'FRAP_001','FRAP_002','FRAP_004','FRAP_006','FRAP_007'},...
                          {'FRAP_000','FRAP_001','FRAP_003','FRAP_005','FRAP_004'}};

            labels = {'Vector','R175'};

        case 'Biosensor GLCM'
            root = 'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\Biosensor Cells\GLCM\';
            
            directories{1} = {'081015_107118'};
            exclude{1} = {{}};
            directories{2} = {'081015_101912'};
            exclude{2} = {{}};
            directories{3} = {'081015_111375'};
            exclude{3} = {{}};
            directories{4} = {'081015_105925'};
            exclude{4} = {{}};
            
            labels = {'flox','met 912','met 375','met 925'};
            
    end
        
    folders = {{},{}};
    subfolders = {{},{}};
    
    for m=1:length(directories)
        idx = 1;
        for j=1:length(directories{m})
            [fol,sub] = GetFRAPSubFolders([root directories{m}{j}]);
            FeedbackMessage('GarvanFrap',['Processing: ' fol]);

            for i=1:length(sub)
                if ~any(strcmp(sub{i},exclude{m}{j}))
                    folders{m}{idx} = fol;
                    subfolders{m}{idx} = sub{i};
                    idx = idx + 1;
                else
                    FeedbackMessage('GarvanFrap',['Excluding ' fol sub{i}])
                end
            end
        end
    end

end
