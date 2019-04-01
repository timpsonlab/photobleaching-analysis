classdef AbstractKymographProcessor < handle
   
    properties
        fh;
        kymographs;
        handles;
    end

    methods(Abstract)
        UpdateDisplay(obj)
    end

    methods
        
        function h = AddFilesLayout(obj, layout, h)
            files_layout = uix.VBox('Parent',layout);
            button_layout = uix.HBox('Parent',files_layout);
            h.add_button = uicontrol('Style','pushbutton','String','Add','Parent',button_layout);
            h.remove_button = uicontrol('Style','pushbutton','String','Remove','Parent',button_layout);
            h.files_list = uicontrol('Style','listbox','Parent',files_layout,'Min',0,'Max',2);
            files_layout.Heights = [30 -1]; 

            h.add_button.Callback = @(~,~) EC(@obj.AddData);
            h.remove_button.Callback = @(~,~) EC(@obj.RemoveData);
            h.files_list.Callback = @(~,~) EC(@obj.UpdateDisplay);
        end
        
        function SetupCallbacks(obj)
            h = obj.handles;
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
                kymograph = LoadKymograph(filename);

                if isempty(kymograph)
                    found_invalid = true;
                    continue;
                end
                
                if isempty(obj.kymographs)
                    obj.kymographs = kymograph;
                    
                    max_t = size(kymograph.data,2) * kymograph.temporal_units_per_pixel;
                    obj.handles.max_time_edit.String = num2str(max_t);
                    
                else
                    obj.kymographs(end+1) = kymograph;
                end
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