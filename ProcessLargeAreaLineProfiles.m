
root =  {'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Large Area\020915 vector DMSO\',...
         'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Large Area\100915 vector DMSO large ROI\'};
excl = {{'FRAP_002','FRAP_005'},{'FRAP_002','FRAP_004'}};

%root = {'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Large Area\100915 175 DMSO large ROI\'};
%excl = {{'FRAP_002' 'FRAP_003' 'FRAP_006' 'FRAP_012'}};

%root = {'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\FRAP Large Area\100915 vector DMSO small ROI\'}
%exl = {'FRAP_001' 'FRAP_003'};

m = 1;

if m == 2
    root = {'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\xenos\Large Area FRAP\190915 96 175\',...
            'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\xenos\Large Area FRAP\220915 92 175\'}
    excl = {{'FRAP_000'},{'FRAP_002','FRAP_004'}};
else
    root = {'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\xenos\Large Area FRAP\200915 18 vector\',...
            'C:\Users\CIMLab\Documents\User Data\Sean\FRAP\xenos\Large Area FRAP\240915 17 vector\'}
    excl = {{'FRAP_000'},{'FRAP_000','FRAP_001','FRAP_002','FRAP_003','FRAP_005'}};
end

R = LoadLineProfiles(root,excl);

%%

% David FLIP
dt =  1.621;
px_per_um = 9.68971753;


rc = linspace(-7,7,600);
combined = zeros(600,255);
combined_norm = zeros(600,255);

figure(1)
for j=1:length(R)

    Rx = R{j};

    n = size(Rx.l2,1);

    [l2uc,r] = GetCorrectedKymograph(Rx);
    r = r / px_per_um;

    
    total = Rx.total / nanmax(Rx.total);
    fitmodel = FitExpWithPlateau(1:length(total),total);
    pb = feval(fitmodel,1:length(total));
    %pb = total';
    
    endn = size(Rx.l2,2);
    endn = min(endn,255);
    
    l2uc = l2uc(:,1:endn,1);
    r = r(:,1);
    
    t = (0:(endn-1)) * dt;

    pb = repmat(pb(1:endn)',[size(l2uc,1) 1]);
    l2uc = l2uc ./ pb; 

    
    
    b = mean(l2uc(:,1:5),2);
    b = repmat(b,[1 size(l2uc,2)]);
    
    l2n = l2uc ./ b; %nanmean(b(:));

    
    
    n = 50;
    kern = ones(n,1) / n;
    l2nc = conv2(l2n,kern,'same');
    
    
    first_after = l2nc(:,6:10);
    first_after = mean(first_after,2);
    [~,bleach_centre_idx] = min(first_after);
    r0 = r(bleach_centre_idx);
    
    l2nn = interp2(t,(r-r0)',l2n,t,rc');
    
    kg{j} = l2nn;
    
    combined_norm = combined_norm + ~isnan(l2nn);
    l2nn(isnan(l2nn)) = 0;
    combined = combined + l2nn;
    
    
    
    
    imagesc(t,r-r0,l2n)
    xlabel('Time (s)');
    ylim([-7 7])
    %xlim([0 600])
    %caxis([0 max(l2uc(:))])
    colorbar
    
    colormap('hot')
    set(gcf,'PaperPositionMode','auto')
    %saveas(gcf,[Rx.folder '..' filesep Rx.subfolder ' kymograph new.png'])
    %drawnow
end

combined = combined ./ combined_norm;
%%

idx = [6 12 16 20 30 50 75 120];
idx = 6:150; 
idx = round(logspace(log10(6),log10(150),20));
idx = 6:10:185;
%idx = round(linspace(6,50,20));


%idx = [idx round(linspace(100,255,10))];


colors = jet(length(idx));
g = [0.4 0.4 0.4];
t2 = t(idx);


figure(2)
PrepFigure(2,15,4)
h = subplot(1,3,[1 2]);
imagesc(t,rc,combined);
colormap('hot')
caxis([0 1.2]);
ylim([-5 5])
xlim([0 300])
%xlabel('Time (s)');
%ylabel('Distance (um)')
hold on;
for j=1:length(idx)
    plot(t2(j),-4.5,'v','MarkerFaceColor',colors(j,:),'MarkerEdgeColor','k')
    plot(t2(j),4.5,'^','MarkerFaceColor',colors(j,:),'MarkerEdgeColor','k')
end
hold off;
set(gca,'XTick',[],'YTick',[]);
%saveas(gcf,[folder 'kymograph combined.png']);



c1 = (colors + 1) / 2;

s = [];
a = [];
s_ci = [];
a_ci = [];


figure(2)
subplot(1,3,3)
hold off;
for j=1:length(idx)
    sel = abs(rc) < 4;
    x = rc(sel)';
    y = combined(:,[idx(j) idx(j)+5]);
    y = mean(y,2);
    
    n = 10;
    kern = ones(1,n)/n;
    
%y = conv(y,kern,'same');

    y = y(sel);
    
    [fit_result,y_fit,ci] = FitGaussian(x,y);
    a(j) = fit_result.a;
    s(j) = fit_result.s;
    s_ci(:,j) = ci(:,2); 
    a_ci(:,j) = ci(:,1);
    if mod(j-1,3) == 0
        plot(x,y,'.','Color',c1(j,:),'MarkerSize',2);
        hold on;
        plot(x,y_fit,'-','Color',colors(j,:),'LineWidth',2);
    end
end
ylabel('Intensity');
xlabel('Distance [\mum]')
hold off;
box off;
ylim([0.1,1.1])

errsel = abs(a) > 2;
s(errsel) = nan;
a(errsel) = nan;
%%
[p,S] = polyfit(t2,s,1);
S.Rinv = inv(S.R);
cov = (S.Rinv*S.Rinv')*S.normr^2/S.df;

sf = polyval(p,t2);

D = p(1)/4; % um^2/s
Dstd = sqrt(cov(1,1))/4;
FeedbackMessage('GarvanFrap',['Diffusion Coeff: ' num2str(D,4) ' +/- ' num2str(Dstd,4) ' um^s/s'])

%%
figure(4)
PrepFigure(4,6,4)
plot(t2,sf,'-','Color',[0.5 0.5 0.5])
hold on;
for j=1:length(idx)
    errorbar(t2(j),s(j),s_ci(1,j)-s(j),s_ci(2,j)-s(j),'o','MarkerSize',4,...
        'MarkerFaceColor',colors(j,:),'MarkerEdgeColor',g,'Color',g);
end
hold off;
    %set(h,'XTick',1:length(idx),'XTickLabel',arrayfun(@(x) num2str(x,3),t2,'UniformOutput',false));
ylabel('\sigma^2 [\mum]');
xlabel('Time [s]');
%ylim([0 3])
box off;
ylim([0 15])
xlim([0 300])
%%

a = a / a(1);

figure(3)
as = 1./(sqrt(s*2*pi));
as = as / as(1) * a(1);

as_ci = 1./sqrt(s_ci*2*pi);
as_ci = as_ci ./ repmat(as_ci(:,1),[1 size(as_ci,2)]) * a(1);



subplot(1,3,m)
hold off;
errorbar(t2,a,a_ci(1,:)-a,a-a_ci(2,:))
hold on;
errorbar(t2,as,as_ci(1,:)-as,as-as_ci(2,:));
ylabel('A')
xlabel('Time (s)');
ylim([0.4 1.2])
%saveas(gcf,[folder 'line plots combined.png']);

q{m} = a+(1-as);
q_ci{m} = sqrt(a_ci.^2 + as_ci.^2);

figure(3)
subplot(1,3,3)
hold off;
for i=1:2
    errorbar(t2,q{i},q_ci{i}(1,:)-q{i},q{i}-q_ci{i}(2,:)); hold on
end
ylim([0.4 1.2])
