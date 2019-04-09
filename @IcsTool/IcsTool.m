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
        
        function kymograph = GetKymograph(obj,idx)
            downsampling = str2double(obj.handles.temporal_downsampling_edit.String);    
            kymograph = obj.kymographs(idx);
            dt_override = str2double(obj.handles.time_interval_edit.String);
            if isfinite(dt_override)
                kymograph.temporal_units_per_pixel = dt_override;
            end
            kymograph = DownsampleKymograph(kymograph, downsampling);
        end
        
        function options = GetOptions(obj)
            options.time_max = str2double(obj.handles.max_time_edit.String);
            options.fit_diffusion = obj.handles.fit_diffusion_popupmenu.Value == 1;
            options.fit_flow = obj.handles.fit_flow_popupmenu.Value == 1;

            options.max_distance = str2double(obj.handles.max_distance_edit.String);
            options.glcm_lim = str2double(obj.handles.glcm_lim_edit.String);
        end
        
    end
    
end