function ProcessGLCM(dataset, max_frame, use_junctions, lim)

    folders = dataset.folders;
    subfolders = dataset.subfolders;
    labels = dataset.labels;

    C = []; Cs = []; CA = [];

    for m=1:length(folders)
        R = cell(1,length(folders{m}));
        for i=1:length(folders{m})
            R{i} = LoadLineProfile(folders{m}{i}, subfolders{m}{i});
        end

        contrast = [];
        idx = 1;

        for j=1:length(R)

            Rx = R{j};
            [l2uc,r] = GetCorrectedKymograph(Rx);

            r = r / Rx.px_per_um;
            l2uc = l2uc(:,1:max_frame,:);

            if isempty(use_junctions)
                sel = 1:size(l2uc,3);
            else
                sel = use_junctions;
            end

            sel = sel(sel <= size(l2uc,3));

            for k=sel
                SaveNormalisedKymograph(l2uc(:,:,k), r(:,k), linspace(0,8,200), [Rx.folder '..\' Rx.subfolder '-' num2str(k) '.tif']);       
                contrast(:,idx) = ComputeKymographOD_GLCM(r(:,k),l2uc(:,:,k),lim);
                idx = idx + 1;
            end
        end 

        contrast_s = nanstd(contrast,[],2) / sqrt(size(contrast,2));    
        contrast_m = nanmean(contrast,2);

        contrast_a{m} = nanmean(contrast,1)';

        CA(m) = nanmean(contrast_a{m});
        CAs(m) = nanstd(contrast_a{m}) / sqrt(length(contrast_a{m}));

        C(:,m) = contrast_m;
        Cs(:,m) = contrast_s;

    end
    
    
        fh = figure(10);
        rout = repmat(linspace(0,2.5,50)',[1 size(C,2)]);

        set(fh,'DefaultAxesFontSize', 6)
        set(fh,'DefaultTextFontSize', 6)

        errorbar(rout,C,Cs);
        box off;
        xlabel('Distance [\mum]');
        ylabel('Contrast')
        xlim([0 2.5])
        ylim  auto
        legend(labels,'Box','off','Location','SouthEast')
        set(fh,'Units','centimeters','GraphicsSmoothing','off');
        set(gca,'TickDir','out')
        p = get(fh,'Position');
        set(fh,'Position',[p(1:2) 6.6 4.5])