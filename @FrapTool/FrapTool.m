classdef FrapTool < handle

    properties
        fh;
        handles;
        
        datasets;
        current_data
        last_folder;
        
        junction_types = {'Bleach','Adjacent','Distant'};
        junction_color = {[1 0 0],[0 1 0],[0 0 1]};
        junctions;
        junction_h;
        junction_type;
        
        tracked_junctions_x;
        tracked_junctions_y;
        
        draw_mode = 'new junction';
    end
   
    
    methods
        function obj = FrapTool

            addpath('layout');

            SetupLayout(obj);
            SetupMenu(obj);
            
            if ispref('FrapTool','last_folder')
                obj.last_folder = getpref('FrapTool','last_folder');
            end
                        
            obj.LoadData(obj.last_folder);
            
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
            uimenu(file_menu,'Label','Refresh','Callback',@(~,~) obj.SetCurrent,'Accelerator','R');
            uimenu(file_menu,'Label','Export Kymographs','Callback',@(~,~) obj.ExportKymographs,'Separator','on');

            tracking_menu = uimenu(obj.fh,'Label','Tracking');
            uimenu(tracking_menu,'Label','Track Junctions...','Callback',@(~,~) obj.TrackJunctions,'Accelerator','T');
        end
        
        function LoadData(obj,root)
            
            if (nargin < 2)
                root = uigetdir(obj.last_folder);
            end
            if root == 0
                return
            end
            
            obj.last_folder = root;
                
            [folder,subfolders] = GetFRAPSubFolders(root);

            wh = waitbar(0,'Loading...');
            for i=2
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
            
            d = obj.current_data;
            
            ax = [obj.handles.image_ax, obj.handles.draw_ax];
            image_h = {'image', 'draw_image'};
            roi_h = {'image_frap_roi', 'draw_frap_roi'};

            if length(d.roi_x) > 1
                roi_x = [d.roi_x(:); d.roi_x(1)];
                roi_y = [d.roi_y(:); d.roi_y(1)];
            end
                
            for i=1:length(ax)
                cla(ax(i));
                obj.handles.(image_h{i}) = imagesc(d.after{1},'Parent',ax(i));
                set(ax(i),'XTick',[],'YTick',[]);
                daspect(ax(i),[1 1 1]);

                hold(ax(i),'on');
                obj.handles.(roi_h{i}) = plot(ax(i), roi_x, roi_y, 'r', 'HitTest', 'off');
            end
                        
            z = zeros(size(d.after{1}));
            obj.handles.mask_image = image(z,'AlphaData',z,'Parent',obj.handles.image_ax);
            
            obj.UpdateDisplay();
            
            obj.handles.draw_image.ButtonDownFcn = @(~,~) obj.MouseDown;
            obj.handles.draw_image.HitTest = 'on';
        end
        
        function UpdateDisplay(obj)
            cur = round(obj.handles.image_scroll.Value);
            
            cur_image = double(obj.current_data.after{cur});
            cur_image =  cur_image / prctile(cur_image(:),99);
            out_im = repmat(cur_image,[1 1 3]);
            out_im(out_im > 1) = 1;
            
            mask_im = zeros(size(cur_image));
            
            ndil = 4;
            
            cmap = [0 0 0
                    1 0 0
                    0 1 0
                    0 0 1];
                        
            for i=1:length(obj.tracked_junctions_x)            
                [~,~,idx] = GetThickLine(size(cur_image),obj.tracked_junctions_x{i}(cur,:),obj.tracked_junctions_y{i}(cur,:),600,ndil); 
                mask_im(idx) = obj.junction_type(i);
            end
            
            %caxis(obj.handles.image_ax,[0 max(cur_image(:))]);
            obj.handles.image.CData = out_im;
            
            obj.handles.mask_image.CData = ind2rgb(mask_im+1,cmap);
            obj.handles.mask_image.AlphaData = 0.8*(mask_im>0);
            
        end
        
        function StartNewJunction(obj, junction_type)
            obj.junction_h(end+1) = plot(obj.handles.draw_ax,nan,nan,'Marker','o','MarkerSize',7,...
                'Color','k','LineStyle','-','MarkerFaceColor',obj.junction_color{junction_type});
            obj.junctions{end+1} = [];
            obj.junction_type(end+1) = junction_type;
            obj.draw_mode = 'new_junction';
    
            names = cell(size(obj.junctions));
            for i=1:length(obj.junctions)
                names{i} = ['Junction ' num2str(i) ' (' obj.junction_types{obj.junction_type(i)} ' junction)'];
            end
            obj.handles.kymograph_select.String = names;
        end

        function MouseDown(obj)
            
            [x0,y0] = obj.GetCurrentPoint();            
  
            switch obj.draw_mode
                case 'new_junction'

                    if isempty(obj.junctions)
                        return
                    end

                    obj.junctions{end}(end+1,:) = [x0,y0];

                    p = obj.junctions{end};
                    set(obj.junction_h(end),'XData',p(:,1),'YData',p(:,2));
                    
                case 'delete'
                    
                    % Find closest junction
                    p = [x0 y0];
                    min_dist = inf;
                    min_jcn = 1;
                    for i=1:length(obj.junctions)
                        dist = sqrt(sum((obj.junctions{i} - p).^2,1));
                        if min(dist) < min_dist
                            min_dist = min(dist);
                            min_jcn = i;
                        end
                    end
    
                    
                    % Remove junction
                    obj.junctions(min_jcn) = [];
                    delete(obj.junction_h(min_jcn));
                    obj.junction_h(min_jcn) = [];
                    
            end
        end

        function [x,y] = GetCurrentPoint(obj)
            pt = get(obj.handles.draw_ax, 'CurrentPoint');
            x = pt(1,1);
            y = pt(1,2); 
        end        
        
        function UndoPoint(obj)
            if ~isempty(obj.junctions)
                obj.junctions{end}(end,:) = [];
                p = obj.junctions{end};
                set(obj.junction_h(end),'XData',p(:,1),'YData',p(:,2));
            end
        end
        
        function DeleteJunction(obj)
            obj.draw_mode = 'delete';
        end
        
        function TrackJunctions(obj)
           
            np = 20;
            
            wh = waitbar(0, 'Tracking Junctions...');
            for i=1:length(obj.junctions)
                x = obj.junctions{i}(:,1);
                y = obj.junctions{i}(:,2);
               
                
                [xt, yt] = TrackJunction(obj.current_data.flow, x, y, true, np);
                
                nb = length(obj.current_data.before);
                xt = [repmat(xt(1,:),[nb 1]); xt]; %#ok
                yt = [repmat(yt(1,:),[nb 1]); yt]; %#ok
                
                obj.tracked_junctions_x{i} = xt;
                obj.tracked_junctions_y{i} = yt;
                waitbar(i/length(obj.junctions));
            end
            close(wh);
            
        end
        
        function UpdateKymograph(obj)
           
            junction = obj.handles.kymograph_select.Value;
            [kymograph,r] = GenerateKymograph(obj, junction);
            
            ax_h = obj.handles.kymograph_ax;
            imagesc(kymograph,'Parent',ax_h);
            ax_h.TickDir = 'out';
            ax_h.Box = 'off';
            
            lim = 500;
            
            
            r = r / obj.current_data.px_per_um;
            contrast = ComputeKymographOD_GLCM(r,kymograph,lim);
            
            h_ax = obj.handles.od_glcm_ax;
            plot(obj.handles.od_glcm_ax,contrast);
            xlabel(h_ax,'Distance');
            ylabel(h_ax,'Contrast');
        end
        
        function ExportKymographs(obj)
           
            if isempty(obj.tracked_junctions_x)
                msgbox('No tracked junctions found to export as kymographs. Please select and track junctions to export as kymographs.',...
                       'Error','warn');
            end
            
            export_folder = uigetdir(obj.last_folder);
            if export_folder == 0
                return;
            end
            
            for i=1:length(tracked_junctions)
                [kymograph,r] = obj.GenerateKymograph(i);
                filename = [obj.current_data.name '_junction_' num2str(i) '_' obj.junction_types{obj.junction_type(i)} '.tif'];
                imwrite(kymograph,[export_folder filesep filename]);
            end
            
        end
        
        function [kymograph,r] = GenerateKymograph(obj, junction)
            
            x = obj.tracked_junctions_x{junction};
            y = obj.tracked_junctions_y{junction};
            
            images = [obj.current_data.before, obj.current_data.after];
            
            results = ExtractTrackedJunctions(images, {x}, {y});
            [kymograph,r] = GetCorrectedKymograph(results);

        end
        
    end
    
end