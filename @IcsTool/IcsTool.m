classdef IcsTool < AbstractKymographProcessor
       
    methods
        
        function obj = IcsTool(parent, fig)
            obj.SetupLayout(parent, fig);
            obj.SetupCallbacks();
        end
        
        function SetupCallbacks(obj)           
            h = obj.handles;
            h.add_button.Callback = @(~,~) EC(@obj.AddData);
            h.remove_button.Callback = @(~,~) EC(@obj.RemoveData);
            h.files_list.Callback = @(~,~) EC(@obj.UpdateDisplay);

            AddCallbackWithValidator(h.max_time_edit, @obj.UpdateDisplay);
        end
        
        function menus = SetupMenu(obj)
            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) EC(@obj.AddData),'Accelerator','O');
            uimenu(file_menu,'Label','Export ICS results...','Callback',@(~,~) EC(@obj.ExportIcsResults),'Accelerator','S');
            
            menus = [file_menu];
        end
        
    end
    
end