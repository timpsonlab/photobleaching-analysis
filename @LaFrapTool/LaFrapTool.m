classdef LaFrapTool < handle
   
    properties
        fh
        handles
    end
    
    methods
        
        function obj = LaFrapTool(parent, fig)
            
            obj.SetupLayout(parent, fig);
            
        end
        
        function SetupLayout(obj, parent, fig)
            
            obj.fh = fig;
            layout = uix.HBox('Parent',parent,'Spacing',5,'Padding',5);
            
            h.files_list = uicontrol('Style','listbox','Parent',layout);
    
            h.tab_panel = uix.TabPanel('Parent',layout);

            % Options sidebar
            options_panel = uipanel(layout,'Title','Options');
            options_layout = uix.VBox('Parent',options_panel,'Spacing',2,'Padding',5);

            layout.Widths = [200 -1 200];

            obj.handles = h;
            
        end
        
        function menus = SetupMenu(obj)
            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) obj.LoadData,'Accelerator','O');
            uimenu(file_menu,'Label','Refresh','Callback',@(~,~) obj.SetCurrent,'Accelerator','R');
            uimenu(file_menu,'Label','Export Recovery Curves...','Callback',@(~,~) obj.ExportRecovery,'Separator','on');
            uimenu(file_menu,'Label','Export Recovery Curves for all Datasets...','Callback',@(~,~) obj.ProcessAll);
            uimenu(file_menu,'Label','Export Kymographs...','Callback',@(~,~) obj.ExportKymographs,'Separator','on');
            
            menus = [file_menu];
        end
        
    end
    
end