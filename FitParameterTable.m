classdef FitParameterTable < handle
    
    properties
        table;
    end
    
        
    methods
        
        function obj = FitParameterTable(parent, params)
           
            data = [params.names', params.initial_values', params.lim_min', params.lim_max', params.fit'];
            column_names = {'Param', 'Initial', 'Min', 'Max', 'Fit?'};
            column_editable = [false, true, true, true, true];
            column_widths = {60 60 60 60 30};
            
            obj.table = uitable('Parent',parent,'Data',data,'ColumnName',column_names,...
                                'ColumnEditable',column_editable,'RowName',[],'ColumnWidth',column_widths);
            
        end
        
        function params = GetParams(obj)
            
            data = obj.table.Data;
            
            params = struct();
            
            for i=1:size(data,1)
                params(i).name = data{i,1};
                params(i).initial = data{i,2};
                params(i).min = data{i,3};
                params(i).max = data{i,4};
                params(i).fit = data{i,5};
            end
            
        end
        
    end
    
end

