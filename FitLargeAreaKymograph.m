
for m=1:2
    
    if m==1
        combined = vcombined2;
    else
        combined = mcombined2;
    end

    model = struct();

    model.koff = 0.01;

    model.fb = 0.9; % bleach fraction
    model.m = 0.94; % steepness of edges
    model.dx = 3.0; % extent of bleach region
    model.x0 = 0;
    model.If = 0.5;
    model.k_bleach = 0; %1e-4;
    model.D = 0.001;
    model.I0 = 1;

    tmax = 400;

    tsel = t < tmax + 5*1.6;
    tsel(1:5) = false;
    tt = t(tsel);
    tt = tt - min(tt);

    rsel = abs(rc) < 4;
    rr = rc(rsel);

    data = combined(rsel,tsel);
    figure(m)
    colormap('hot')
    subplot(4,1,1)
%    model = OptimiseModel(model,{'fb','m','x0','I0'},[0 0 -5, 0],[1 5 5, 1.5],rr,0,data(:,1),@FRAPg);
    model = OptimiseModel(model,{'fb','x0','I0'},[0 -5, 0],[1, 5, 1.5],rr,0,data(:,1),@FRAPg);
    ylim([0 1.2])

    subplot(4,1,2)
    imagesc(t,x,data);
    xlim([0 tmax])
    ylim([-max(rr) max(rr)])
    colorbar
    caxis([0 1.2])


    subplot(4,1,3)
    %[model,fval] = OptimiseModel(model,{'D','koff','If','k_bleach'},[0 0 0 0],[0.1 0.1 1 1e-3],rr,tt,data,@FRAPg)
    [model,fval,fitted] = OptimiseModel(model,{'D','koff','If'},[0 0 0],[1 1 1],rr,tt,data,@FRAPg);
    disp(model);
    fmodel(m) = model;
    disp('Done!');
    
    subplot(4,1,4);
    im = imfuse(data,fitted);
    imagesc(t,x,im)
 
    %%
    %{
    figure(3)
    %model.If = 0
    %model.dx = 3

    f = {0 0.5 1 2 5};

    for i=1:5
        for j=1:5

            subplot(5,5,i+5*(j-1))
            m2 = model;
            m2.koff = f{i} * m2.koff;
            m2.D = f{j} * m2.D;
            A = FRAPg(m2,rr,tt);
            imagesc(A);
            caxis([0 1.2])

            if (j==1)
                title([num2str(f{i}) '\timesk_{off}'])
            end
            if (i==1)
                ylabel([num2str(f{j}) '\timesD'],'FontWeight','bold')
            end

        end
    end
    %}
    %%

    continue
    
    %model.If = 0
    %model.dx = 3
    %model.k_bleach = 0
    f = {0 1 5};
            idx = [1 10 50 100];
    figure(3)
    clf
    for i=1:length(f)
        for j=1:length(f)

            h = subplot(length(f),length(f),i+length(f)*(j-1));
            m2 = model;
            m2.koff = f{i} * m2.koff;
            m2.D = f{j} * m2.D;
            A = FRAPg(m2,rr,tt);

            m2.m = 100;
            AR = FRAPg(m2,rr,0);
            hold on; 
            plot(rr,AR,'Color',[0.8 0.8 0.8]);


            set(h,'ColorOrderIndex',1);
            plot(rr,data(:,idx),'o','MarkerSize',1);
            hold on;
            set(h,'ColorOrderIndex',1);


            A = A(:,idx);
            p = plot(rr,A,'LineWidth',2);

            str = arrayfun(@(q) [num2str(tt(q),3) ' s'], idx, 'UniformOutput', false);

            legend(p,'Strings',str,'Location','southeast','Box','off')



            ylim([0 1])
            box off;
            set(h,'TickDir','out')

            if (j==1)
                title([num2str(f{i}) '\timesk_{off}'])
            end
            if (i==1)
                ylabel([num2str(f{j}) '\timesD'],'FontWeight','bold')
            end


        end
    end
end