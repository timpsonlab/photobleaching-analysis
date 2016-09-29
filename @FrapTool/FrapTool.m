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
        
        rois;
        tracked_roi_centre;
        
        tracked_junctions;
        
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
            uimenu(file_menu,'Label','Export Recovery Curves...','Callback',@(~,~) obj.ExportRecovery,'Separator','on');
            uimenu(file_menu,'Label','Export Kymographs...','Callback',@(~,~) obj.ExportKymographs,'Separator','on');

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
            
            rec_h = obj.handles.recovery_ax;
            cla(rec_h);
            recovery = obj.GetRecovery();
            plot(rec_h,recovery);
            hold(rec_h,'on');

            recovery = obj.GetRecovery('stable');
            plot(rec_h,recovery);
            
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
                        
            for i=1:length(obj.tracked_junctions)            
                [~,idx] = GetThickLine(size(cur_image),obj.tracked_junctions{i}(cur,:),600,ndil); 
                mask_im(idx) = obj.junction_type(i);
            end
            
            obj.handles.image.CData = out_im;
            
            obj.handles.mask_image.CData = ind2rgb(mask_im+1,cmap);
            obj.handles.mask_image.AlphaData = 0.8*(mask_im>0);
                        
        end
        
        function recovery = GetRecovery(obj,opt)
            d = obj.current_data;

            roi = d.roi_x + 1i * d.roi_y;
            if nargin > 1 && strcmp(opt,'stable')
                % Get centre of roi and stabalise using optical flow
                p = mean(roi);
                roi = roi - p;
                p = TrackJunction(obj.current_data.flow,p);
                [~,~,recovery] = ExtractRecovery(d.before, d.after, roi, p); 
            else
                [~,~,recovery] = ExtractRecovery(d.before, d.after, roi);
            end
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
            
            p0 = obj.GetCurrentPoint();    
            
            switch obj.draw_mode
                case 'new_junction'

                    if isempty(obj.junctions)
                        return
                    end

                    obj.junctions{end}(end+1) = p0;

                    p = obj.junctions{end};
                    set(obj.junction_h(end),'XData',real(p),'YData',imag(p));
                    
                case 'delete'
                    
                    % Find closest junction
                    min_dist = inf;
                    min_jcn = 1;
                    for i=1:length(obj.junctions)
                        dist = abs(obj.junctions{i} - p0);
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

        function p = GetCurrentPoint(obj)
            pt = get(obj.handles.draw_ax, 'CurrentPoint');
            p = pt(1,1) + 1i * pt(1,2);
        end        
        
        function UndoPoint(obj)
            if ~isempty(obj.junctions)
                obj.junctions{end}(end,:) = [];
                p = obj.junctions{end};
                set(obj.junction_h(end),'XData',real(p),'YData',imag(p));
            end
        end
        
        function DeleteJunction(obj)
            obj.draw_mode = 'delete';
        end
        
        function TrackJunctions(obj)
           
            np = 20;
            
            wh = waitbar(0, 'Tracking Junctions...');
            for i=1:length(obj.junctions)
                p = obj.junctions{i};
                
                t = TrackJunction(obj.current_data.flow, p, true, np);
                
                nb = length(obj.current_data.before);
                t = [repmat(t(1,:),[nb 1]); t];
                
                obj.tracked_junctions{i} = t;
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
           
            if isempty(obj.tracked_junctions)
                msgbox('No tracked junctions found to export as kymographs. Please select and track junctions to export as kymographs.',...
                       'Error','warn');
            end
            
            export_folder = uigetdir(obj.last_folder);
            if export_folder == 0
                return;
            end
            
            for i=1:length(obj.tracked_junctions)
                [kymograph,r] = obj.GenerateKymograph(i);
                filename = [obj.current_data.name '_junction_' num2str(i) '_' obj.junction_types{obj.junction_type(i)} '.tif'];
                imwrite(kymograph,[export_folder filesep filename]);
            end
            
        end
        
        function [kymograph,r] = GenerateKymograph(obj, junction)
            
            p = obj.tracked_junctions{junction};
            
            images = [obj.current_data.before, obj.current_data.after];
            
            results = ExtractTrackedJunctions(images, {p});
            [kymograph,r] = GetCorrectedKymograph(results);

        end
        
    end
    
end