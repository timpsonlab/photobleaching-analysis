classdef JunctionArtist < handle

    properties
        junctions   
    end
    
    properties(Access=private)
        draw_mode;
        handles;
        file;
        dataset_idx;
    end
    
    events
        JunctionsChanged;
    end
    
    methods
        
        function obj = JunctionArtist(parent)
            
            if nargin < 1
                parent = figure();
            end
            
            % Drawing tab
            drawing_layout = uix.VBox('Parent',parent,'Spacing',5,'Padding',5);

            drawing_buttons_layout = uix.HBox('Parent',drawing_layout);

            for i=1:length(Junction.types)
                h.new_junction(i) = uicontrol('Style','pushbutton','String',['Add ' Junction.types{i} ' Jcn'],...
                                              'Parent',drawing_buttons_layout,...
                                              'Callback',@(~,~) obj.StartNewJunction(i),...
                                              'ForegroundColor',Junction.junction_color{i});
            end
            h.undo_button = uicontrol('Style','pushbutton','String','Undo',...
                                      'Parent',drawing_buttons_layout,'Callback',@(~,~) obj.UndoPoint);
            h.delete_button = uicontrol('Style','pushbutton','String','Delete',...
                                      'Parent',drawing_buttons_layout,'Callback',@(~,~) obj.DeleteJunction);

            uix.Empty('Parent',drawing_buttons_layout);

            h.save_button = uicontrol('Style','pushbutton','String','Save',...
                                      'Parent',drawing_buttons_layout,'Callback',@(~,~) obj.SaveJunctions);


            uix.Empty('Parent',drawing_buttons_layout);
            set(drawing_buttons_layout,'Widths',[100*ones(1,length(Junction.types)+2) 10 100 -1]);

            h.image_ax = axes('Parent',drawing_layout);
            h.image = imagesc(0,'Parent',h.image_ax);
            h.frap_roi = plot(h.image_ax,nan,nan,'r');

            drawing_layout.Heights = [22 -1];
            
            obj.handles = h;
            
        end
        
        function SetDataset(obj, im, roi, file, dataset_idx)
                
            obj.file = file;
            obj.dataset_idx = dataset_idx;
            
            ax = obj.handles.image_ax;
            cla(ax);
            obj.handles.image = imagesc(im,'Parent',ax);
            colormap(ax,'gray');
            set(ax,'XTick',[],'YTick',[]);
            daspect(ax,[1 1 1]);

            hold(ax,'on');
            
            [roi_x,roi_y] = roi.GetCoordsForPlot();
            obj.handles.roi_h = plot(ax, roi_x, roi_y, 'g', 'HitTest', 'off');
            
            obj.handles.image.ButtonDownFcn = @(~,~) obj.MouseDown;
            obj.handles.image.HitTest = 'on';
            
            for i=1:length(obj.junctions)
                delete(obj.junctions(i));
            end
            obj.junctions = [];

            jcns = obj.LoadJunctions();
            if length(jcns) >= obj.dataset_idx
                obj.junctions = jcns{obj.dataset_idx};
            end
            
            for i=1:length(obj.junctions)
                obj.junctions(i).CreatePlot(obj.handles.image_ax);
            end
            
            notify(obj,'JunctionsChanged');
            
        end
        
        function StartNewJunction(obj, junction_type)
            j = Junction(obj.handles.image_ax,junction_type);
            
            if isempty(obj.junctions)  
                obj.junctions = j;
            elseif obj.junctions(end).IsEmpty()
                obj.junctions(end) = j;
            else
                obj.junctions(end+1) = j;
            end

            notify(obj,'JunctionsChanged');
            
            obj.draw_mode = 'new_junction';
        end
        
        function MouseDown(obj)

            p0 = obj.GetCurrentPoint();    

            if isempty(obj.junctions)
                return
            end

            switch obj.draw_mode
                case 'new_junction'

                    obj.junctions(end).AddPosition(p0);

                case 'delete'

                    % Find closest junction
                    dist = zeros(size(obj.junctions));
                    for i=1:length(obj.junctions)
                        dist(i) = obj.junctions(i).ShortestDistanceToPosition(p0);
                    end
                    [~,min_jcn] = min(dist);

                    % Remove junction
                    delete(obj.junctions(min_jcn));
                    obj.junctions(min_jcn) = [];
                    
                    notify(obj,'JunctionsChanged');
            end
        end

        function p = GetCurrentPoint(obj)
            pt = get(obj.handles.image_ax, 'CurrentPoint');
            p = pt(1,1) + 1i * pt(1,2);
        end        

        function UndoPoint(obj)
            if ~isempty(obj.junctions)
                obj.junctions(end).RemoveLastPosition();
            end
        end

        function DeleteJunction(obj)
            obj.draw_mode = 'delete';
        end

        function SaveJunctions(obj)
            [junctions, save_name] = LoadJunctions(obj); %#ok
            junctions{obj.dataset_idx} = obj.junctions; %#ok
            save(save_name,'junctions');
        end

        function [jcns, save_name] = LoadJunctions(obj)
            [path, file] = fileparts(obj.file);
            save_name = [path filesep file '-junctions.mat'];
            jcns = {};
            if exist(save_name,'file')
                j = load(save_name);
                if isfield(j,'junctions')
                    jcns = j.junctions;
                end
            end
        end
        
        function names = GetJunctionNames(obj)
            names = cell(size(obj.junctions));
            for i=1:length(obj.junctions)
                names{i} = ['Junction ' num2str(i) ' (' Junction.types{obj.junctions(i).type} ' junction)'];
            end
        end
    
    end

end