function AssembleCurves(root, folders)

    FeedbackMessage('GarvanFrap','Assembling FRAP recovery curves')

    if ~exist([root 'Plots'], 'dir')
        mkdir([root 'Plots'])
    end
    
    figure(10)
    for i=1:length(folders)

        files = dir([root folders{i} filesep '* recovery.csv']);

        t1 = table();
        t2 = table();

        for j=1:length(files)

            name = files(j).name;
            id = name(1:8);

            data = csvread([root folders{i} filesep name]);

            t1.(id) = data(:,1) * 100;
            t2.(id) = data(:,2) * 100;

            plot(data(:,1:2));
            title([folders{i} ' ' id], 'Interpreter', 'none');
            ylim([0.2 1.3]);
            ylabel('Normalised Intensity');
            xlabel('Frame #');
            legend({'Untracked', 'Tracked'},'Box','off');
            saveas(gcf,[root 'Plots\' folders{i} ' ' id '.png'])

        end

        file = [root folders{i} '.xls'];
        writetable(t1,file,'Sheet','Tracked');
        writetable(t2,file,'Sheet','Untracked');
        DeleteDefaultExcelSheets(file);
        
    end