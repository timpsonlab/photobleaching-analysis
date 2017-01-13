function FitKymograph(obj)
   
    [r,t,kymograph,n] = obj.GenerateCombinedKymograph();
    
    t = t((n+1):end);
    t = t - t(1);
    kymograph = kymograph(:,(n+1):end);

    bleach_params = obj.handles.bleach_param_table.GetParams();
    recovery_params = obj.handles.recovery_param_table.GetParams();

    figure(102)

    model = struct();
    model.I0 = 1; % inital intensity
    model.dx = 3.0; % extent of bleach region
    model.x0 = 0; % bleach centre
    model.m = 10; % steepness of edges
    model.fb = 0.8; % bleach fraction

    model.If = 0.5; % immobile fraction
    model.D = 0.0001; % Diffusion coefficent
    model.koff1 = 0.01; % Transport rate 1
    model.koff2 = 0.001; % Transport rate 2
    model.kf1 = 0.5;
    
    model.k_bleach = 0;

    % Set initial values
    for p = [bleach_params recovery_params]
        model.(p.name) = p.initial;
    end

    % only fit selected parameters
    bleach_params = bleach_params([bleach_params.fit]);
    recovery_params = recovery_params([recovery_params.fit]);

    colormap('hot')
    subplot(4,1,1)
    model = OptimiseModel(model,{bleach_params.name},[bleach_params.min],[bleach_params.max],r,0,kymograph(:,1),@FRAPg,false);
    ylim([0 1.2])

    subplot(4,1,2)
    imagesc(t,r,kymograph);
    ylim([-max(r) max(r)])
    colorbar
    caxis([0 1.2])


    subplot(4,1,3)
    %[model,fval] = OptimiseModel(model,{'D','koff','If','k_bleach'},[0 0 0 0],[0.1 0.1 1 1e-3],rr,tt,data,@FRAPg)
    [model,fval,fitted] = OptimiseModel(model,{recovery_params.name},[recovery_params.min],[recovery_params.max],r,t,kymograph,@FRAPg,false);
        
    subplot(4,1,4)
    im = abs(kymograph-fitted);
    imagesc(im);
    caxis([0 0.4])

    fields = fieldnames(model);

    for i=1:length(fields)
        data(i,1) = model.(fields{i});
    end

    obj.handles.fit_table.Data = data;
    obj.handles.fit_table.RowName = fields;

end