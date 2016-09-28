classdef FrapTool < handles

    properties
        fh;
        handles;
    end
    
   
    
    methods
        function obj = FrapTool

            addpath('layout');

            SetupLayout(obj);
            SetupMenu(obj);
            
        end
        
        function SetupMenu(obj)

            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@LoadData)

        end
    end
    
end