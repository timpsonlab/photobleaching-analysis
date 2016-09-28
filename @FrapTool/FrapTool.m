classdef FrapTool < handle

    properties
        fh;
        handles;
        
        datasets;
        current_data
        last_folder;
    end
   
    
    methods
        function obj = FrapTool

            addpath('layout');

            SetupLayout(obj);
            SetupMenu(obj);
            
            if ispref('FrapTool','last_folder')
                obj.last_folder = getpref('FrapTool','last_folder');
            end
            
        end
        
        function set.last_folder(obj,value)
            if ischar(value)
                obj.last_folder = value;
                setpref('FrapTool','last_folder',value);
            end
        end
        
        function SetupMenu(obj)

            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) obj.LoadData,'Accelerator','O');

        end
        
        function LoadData(obj)
            
            root = uigetdir(obj.last_folder);
            
            if root == 0
                return
            end
            
            obj.last_folder = root;
                
            [folder,subfolders] = GetFRAPSubFolders(root);

            wh = waitbar(0,'Loading...');
            for i=1:1
                [obj.current_data,obj.datasets(i).cache_file] = LoadFRAPData(folder,subfolders{i});
                obj.datasets(i).image = obj.current_data.before{1};
                waitbar(i/length(subfolders),wh);
            end
            close(wh);
            
            obj.SetCurrent();
            
        end
        
        function SetCurrent(obj)
        
            n = length(obj.current_data.after);
            obj.handles.image_scroll.Max = n;
            obj.handles.image_scroll.Value = 1;
            obj.handles.image_scroll.SliderStep = [1/n 1/n];
            
            cla(obj.handles.image_ax);
            obj.handles.image = imagesc(obj.current_data.after{1},'Parent',obj.handles.image_ax);
            set(obj.handles.image_ax,'XTick',[],'YTick',[]);
            
        end
        
        function UpdateDisplay(obj)
            cur = round(obj.handles.image_scroll.Value);
            
            cur_image = obj.current_data.after{cur};
            caxis(obj.handles.image_ax,[0 max(cur_image(:))]);
            set(obj.handles.image,'CData',cur_image);
            
        end
        
    end
    
end