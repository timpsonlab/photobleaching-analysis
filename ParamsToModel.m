function model = ParamsToModel(params)

    fields = fieldnames(params);
    
    model = struct();
    
    for i=1:length(fields)
        p = params.(fields{i});
        for j=1:size(p,1)    
            for k=1:size(p,2)
                model.(fields{i})(j).(p(j,k).name) = p(j,k).initial;
            end
        end
    end

end