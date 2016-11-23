classdef LaFrapTool < handle
   
    properties
        fh;
        kymographs;
        handles;
    end
    
    methods
        
        function obj = LaFrapTool(parent, fig)
            
            obj.SetupLayout(parent, fig);
            obj.SetupCallbacks();
            
        end
        

        function SetupCallbacks(obj)
           
            h = obj.handles;
            h.add_button.Callback = @(~,~) obj.AddData();
            h.remove_button.Callback = @(~,~) obj.RemoveData();
            h.files_list.Callback = @(~,~) obj.UpdateDisplay();
            h.include_outliers_popup.Callback = @(~,~) obj.UpdateDisplay();
            h.spatial_display_popup.Callback = @(~,~) obj.UpdateDisplay();
            
            AddCallbackWithValidator(h.distance_edit, @obj.UpdateDisplay);
            AddCallbackWithValidator(h.max_time_edit, @obj.UpdateDisplay);
        end
        
        function menus = SetupMenu(obj)
            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) obj.AddData,'Accelerator','O');
            uimenu(file_menu,'Label','Refresh','Callback',@(~,~) obj.SetCurrent,'Accelerator','R');
            uimenu(file_menu,'Label','Export Recovery Curves...','Callback',@(~,~) obj.ExportRecovery,'Separator','on');
            uimenu(file_menu,'Label','Export Recovery Curves for all Datasets...','Callback',@(~,~) obj.ProcessAll);
            uimenu(file_menu,'Label','Export Kymographs...','Callback',@(~,~) obj.ExportKymographs,'Separator','on');
            
            menus = [file_menu];
        end
        
        function UpdateList(obj)
           
            if ~isempty(obj.kymographs)
                names = {obj.kymographs.name};
            else
                names = {};
            end
            
            old_v = obj.handles.files_list.Value;
            obj.handles.files_list.String = names;
            obj.handles.files_list.Value = old_v(old_v <= length(names)); 
        end
        
        function AddData(obj)
            
            if (nargin < 2)
                [file, root] = uigetfile('*.tif','Choose File...',GetLastFolder(obj.fh),'MultiSelect','on');
            end
            if ~iscell(file) && ~ischar(file)
                return
            end

            if ~iscell(file)
                file = {file};
            end
            
            found_invalid_file = false;
            
            for i=1:length(file)
                filename = [root file{i}];
                info = imfinfo(filename);
                
                if info.ImageDescription(1) ~= '{'
                    found_invalid_file = true;
                    continue;
                end
                
                kymograph = loadjson(info.ImageDescription);
                
                if ~isfield(kymograph,'Kymograph')
                    found_invalid_file = true;
                    continue;
                end
                                
                kymograph = kymograph.Kymograph;
                
                if ~isfield(kymograph,'type') || kymograph.type ~= 1 % bleach
                    found_invalid_file = true;
                    continue;
                end
                
                kymograph.data = imread(filename,'Info',info);
                kymograph.file = filename;
                kymograph.name = file{i};
                
                if isempty(obj.kymographs)
                    obj.kymographs = kymograph;
                    
                    max_t = size(kymograph.data,2) * kymograph.temporal_units_per_pixel;
                    obj.handles.max_time_edit.String = num2str(max_t);
                    
                else
                    obj.kymographs(end+1) = kymograph;
                end;
            end
            
            if found_invalid_file
                warndlg('At least one file was not recognised as a valid kymograph from a bleach region','Errors occured loading data');
            end
            
            obj.UpdateList();
            
        end
        
        function RemoveData(obj)
        
            value = obj.handles.files_list.Value;
            
            if ~isempty(value)
                obj.kymographs(value) = [];
                obj.handles.files_list.Value = 1;
                obj.UpdateList();
            end
            
            
        end
        
    end
    
end