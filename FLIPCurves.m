
[folders,subfolders,root] = GetFRAPDataset('Cell FLIP');

figure(1)
clf(1)

c{1} = [1,0.4,0.4;
        0.2,0.6,1;
        1,0.75,0.5];
c{2} = [0.6,0,0;
        0,0,0.6;
        1,0.5,0];
    
style = {'-','-'};
        
end_pts_adj = {};
end_pts = {};
end_pts_dist = {};

for m=1:length(folders)

    R = {};    
    for j=1:length(folders{m})
        R{end+1} = LoadLineProfile(folders{m}{j},subfolders{m}{j});
    end
    
    % David FLIP
    dt =  1.621;
    px_per_um = 16.957;

    bleach = [];
    adj = [];
    distant = [];

    t = (0:504) * dt;
        
    for j=1:length(R)

        Rx = R{j};
        n = size(Rx.l2,1);

        [l2uc,r] = GetCorrectedKymograph(Rx);
        r = r / px_per_um;

        sz = size(l2uc);
        b = nanmean(nanmean(l2uc(:,1:5,:),2),1);
        b = repmat(b,[sz(1:2) 1]);

        l2n = l2uc ./ b;

        rnge = (j*2-1):(j*2);
        
        bleach(:,j) = nanmean(l2n(:,:,1),1);
        adj(:,rnge) = nanmean(l2n(:,:,2:3),1);
        distant(:,rnge) = nanmean(l2n(:,:,4:5),1);
     
    end
    
    dm = mean(distant,2);
    x = 1:sz(2);
    fitresult = FitExpWithPlateau(x,dm');
    pb = feval(fitresult,x);

    pbr1 = repmat(pb,[1 length(R)]);
    pbr2 = repmat(pb,[1 2*length(R)]);
   
    bleach = 100*bleach ./ pbr1;
    adj = 100*adj ./ pbr2;
    distant = 100*distant ./ pbr2;
    
    bleachm{m} = mean(bleach,2);
    adjm{m} = mean(adj,2);
    distantm{m} = mean(distant,2);
    
    bleachs{m} = std(bleach,[],2) / sqrt(size(bleach,2));
    adjs{m} = std(adj,[],2) / sqrt(size(adj,2));
    distants{m} = std(distant,[],2) / sqrt(size(distant,2));
    
    end_pts{m} = mean(bleach((end-20):end,:))';
    end_pts_adj{m} = mean(adj((end-20):end,:))'; 
    end_pts_dist{m} = mean(distant((end-20):end,:))';
    
end
%%

figure(1);
PrepFigure(gcf,12,6);

sel = 1:2:505;
hold on;

opacity = 0.5;

ErrorRegion(t',bleachm{1},bleachs{1},c{1}(1,:),opacity);
ErrorRegion(t',bleachm{2},bleachs{2},c{2}(1,:),opacity);

ErrorRegion(t',distantm{1},distants{1},c{1}(3,:),opacity);
ErrorRegion(t',distantm{2},distants{2},c{2}(3,:),opacity);

ErrorRegion(t',adjm{1},adjs{1},c{1}(2,:),opacity);
ErrorRegion(t',adjm{2},adjs{2},c{2}(2,:),opacity);

plot(t(sel),bleachm{1}(sel),style{1},'Color',c{1}(1,:),'LineWidth',1);
plot(t(sel),bleachm{2}(sel),style{1},'Color',c{2}(1,:),'LineWidth',1);
plot(t(sel),adjm{1}(sel),style{1},'Color',c{1}(2,:),'LineWidth',1);
plot(t(sel),adjm{2}(sel),style{1},'Color',c{2}(2,:),'LineWidth',1);
plot(t(sel),distantm{1}(sel),style{1},'Color',c{1}(3,:),'LineWidth',1);
plot(t(sel),distantm{2}(sel),style{1},'Color',c{2}(3,:),'LineWidth',1);


ylabel('Fluorescence Intensity [%]');
xlabel('Time [s]');
box off
set(gca,'TickDir','out')
ylim([20 120]); xlim([0 800])