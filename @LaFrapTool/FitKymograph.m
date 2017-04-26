function FitKymograph(obj)
   
    [r,t,kymograph,n] = obj.GenerateCombinedKymograph();
    
    t = t((n+1):end);
    t = t - t(1);
    kymograph = kymograph(:,(n+1):end);

    params.bleach = obj.handles.bleach_param_table.GetParams();
    for i=1:length(obj.handles.recovery_param_table)
        params.component(i,:) = obj.handles.recovery_param_table(i).GetParams();
    end

    model = ParamsToModel(params);
    
    figure(102)

    colormap('hot')
    subplot(4,1,1)
    model = OptimiseModel(model,params,'bleach',r,0,kymograph(:,1),@FRAPg2,false);
    ylim([0 1.2])

    subplot(4,1,2)
    imagesc(t,r,kymograph);
    ylim([-max(r) max(r)])
    colorbar
    caxis([0 1.2])


    subplot(4,1,3)
    %[model,fval] = OptimiseModel(model,{'D','koff','If','k_bleach'},[0 0 0 0],[0.1 0.1 1 1e-3],rr,tt,data,@FRAPg)
    [model,fval,fitted] = OptimiseModel(model,params,'component',r,t,kymograph,@FRAPg2,false);
        
    subplot(4,1,4)
    im = abs(kymograph-fitted);
    imagesc(t,r,im);
    caxis([0 0.4])
    colorbar

    data = [];
    
    fields = fieldnames(model.component);
    for j=1:length(model.component)
        for i=1:length(fields)
            data(i,j) = model.component(j).(fields{i});
        end
    end
    names = fields;

    names = [names; {'res'}];
    data(end+1,1) = fval;
    
    fields = fieldnames(model.bleach);
    for i=1:length(fields)
        data(end+1,1) = model.bleach.(fields{i});
    end
    names = [names; fields];

    
    obj.handles.fit_table.Data = data;
    obj.handles.fit_table.RowName = names;

end