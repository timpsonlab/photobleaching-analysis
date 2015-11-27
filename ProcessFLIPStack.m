% Example script to calculate and display FLIP results from the bleach
% region, regions 3um from the bleach region and distant junctions

offsets_um = [0 -3 3];

[folders,subfolders,root] = GetFRAPDataset(dataset);

% Cycle through each dataset and calculate FLIP curves
results = cell(length(folders));
for m=1:length(folders)
    results{m} = cell(length(folders{m}));
    for j=1:length(folders{m})
        frap = LoadFRAPData(folders{m}{j}, subfolders{m}{j});
        points = LoadPoints(folders{m}{j}, subfolders{m}{j});
        R = LoadLineProfile (folders{m}{j}, subfolders{m}{j});
                
        result = ComputeFLIPCurvesAtOffsetsFromBleach(frap, points.x, points.y, R, offsets_um);
        results{m}{j} = result;
    end
end
FeedbackMessage('GarvanFrap','Complete!')


save([root 'FLIP results selected.mat'],'results');
%%

figure(2)
PrepFigure(gcf,12,6);
    
c{1} = [1,0.4,0.4;
        0.2,0.6,1;
        1,0.75,0.5];
c{2} = [0.6,0,0;
        0,0,0.6;
        1,0.5,0];
    

dt =  1.621;

% Calculate timepoints
nt = length(results{1}{1}.distant);
t = dt * (0:(n-1));

% End time point
t_end = 400;
endp = round(t_end/dt); 

% Display results
for m=1:length(folders)

    reg = [];
    distant = [];
        
    % Get mean, std err of regions
    for i=1:length(selresults{m})
        reg(:,:,i) = selresults{m}{i}.regions;
        distant(:,i) = selresults{m}{i}.distant / selresults{m}{i}.distant(1);
    end
    
    distant = distant * 100;
    distantv = mean(distant,2);
    distants = std(distant,[],2) / sqrt(size(distant,2));
    
    vmx = reg(1,:,:);
    vmx = repmat(vmx, [size(reg,1) 1 1]);
    reg = reg ./ vmx;
    
    n = size(reg,3);
    
    % Reorder data to get bleached and ajacent regions
    reg_b = 100*squeeze(reg(:,1,:));
    reg_a = 100*reshape(reg(:,[2 3],:),[501 2*n]);
        
    vbv = mean(reg_b,2);
    vbs = std(reg_b,[],2) / sqrt(size(reg_b,2));

    vav = mean(reg_a,2);
    vas = std(reg_a,[],2) / sqrt(size(reg_a,2));

    % Get last 5 points to calculate retained fraction
    decays{m,1} = mean(reg_b((endp-5):endp,:),1)';
    decays{m,2} = mean(reg_a((endp-5):endp,:),1)';
    decays{m,3} = mean(distant((endp-5):endp,:),1)';
    
    
    labels = {'Bleach' '3.0um' 'Distant'};

    % Display FLIP curves
    hold on;
    ErrorRegion(t',vbv,vbs,c{m}(1,:),opacity);
    ErrorRegion(t',vav,vas,c{m}(2,:),opacity);
    ErrorRegion(t',distantv,distants,c{m}(3,:),opacity);
    plot(t,vbv,'Color',c{m}(1,:));
    plot(t,vav,'Color',c{m}(2,:));
    plot(t,distantv,'Color',c{m}(3,:));
    ylim([20 120])
    xlim([0 t_end])
    ylabel('Fluorescence Intensity [%]');
    xlabel('Time [s]')
    set(gca,'TickDir','out')
     
end