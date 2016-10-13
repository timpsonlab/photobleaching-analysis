classdef FrapTool < handle

    properties
        fh;
        handles;
        
        reader;
        
        datasets;
        current_index;
        data;
        last_folder;
                
        junction_types = {'Bleach','Adjacent','Distant'};
        
        junctions = [];
        
        rois;
        tracked_roi_centre;
                
        draw_mode = 'new junction';
    end
   
    
    methods
        function obj = FrapTool

            addpath('layout');

            obj.SetupLayout();
            obj.SetupMenu();
            obj.SetupCallbacks();
            
            if ispref('FrapTool','last_folder')
                obj.last_folder = getpref('FrapTool','last_folder');
            end
                        
            %obj.LoadData(obj.last_folder);
            
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
        
        function SetupCallbacks(obj)
            h = obj.handles;
            h.files_list.Callback = @(list,~) obj.SwitchDataset(list.Value);
            h.reload_button.Callback = @(~,~) obj.SwitchDataset(h.files_list.Value);
        end
        
        
        function LoadData(obj,root)
            
            if (nargin < 2)
                [file, root] = uigetfile('*.*','Choose File...',obj.last_folder);
            end
            if file == 0
                return
            end
            
            obj.last_folder = root;
            obj.reader = FrapDataReader([root file]);
                       
            %[obj.folder,obj.subfolders] = GetFRAPSubFolders(root);
            
            obj.UpdateDatasetList();
        end
        
        function UpdateDatasetList(obj)
           obj.handles.files_list.String = obj.reader.groups;
           obj.handles.files_list.Value = 1;
        end
        
        function SwitchDataset(obj,i)
          
            obj.current_index = i;
            obj.data = obj.reader.GetGroup(obj.reader.groups{i});
            
            options.use_drift_compensation = obj.handles.drift_compensation_popup.Value == 2;
            options.image_smoothing_kernel_width = getNumFromPopup(obj.handles.image_smoothing_popup);
            options.flow_smoothing_kernel_width = getNumFromPopup(obj.handles.flow_smoothing_popup);
            options.frame_binning = getNumFromPopup(obj.handles.frame_binning_popup);
            
            if options.use_drift_compensation
                FeedbackMessage('GarvanFrap','Performing drift compensation');
                obj.data.after = CompensateDrift(obj.data.after, options);
            end

            FeedbackMessage('GarvanFrap','Computing Optical Flow');
            obj.data.flow = ComputeOpticalFlow(obj.data.after,options);
            
            FeedbackMessage('GarvanFrap','Finished Loading');
            
            for i=1:length(obj.junctions)
                delete(obj.junctions(i));
            end
            obj.junctions = [];
            
            jcns = obj.LoadJunctions();
            if length(jcns) >= obj.current_index
                obj.junctions = jcns{obj.current_index};
            end
                        
            obj.UpdateKymographList();
            
            
            obj.SetCurrent();

            for i=1:length(obj.junctions)
                obj.junctions(i).CreatePlot(obj.handles.draw_ax);
            end

            
            function v = getNumFromPopup(h)
                v = str2double(h.String{h.Value}); 
            end
            
        end
        
        function SetCurrent(obj)
        
            n = length(obj.data.after);
            obj.handles.image_scroll.Max = n;
            obj.handles.image_scroll.Value = 1;
            obj.handles.image_scroll.SliderStep = [1/n 1/n];
            
            d = obj.data;
            
            ax = [obj.handles.image_ax, obj.handles.draw_ax];
            image_h = {'image', 'draw_image'};
            roi_h = {'image_frap_roi', 'draw_frap_roi'};

            if length(d.roi.x) > 1
                roi_x = [d.roi.x(:); d.roi.x(1)];
                roi_y = [d.roi.y(:); d.roi.y(1)];
            end
                
            for i=1:length(ax)
                cla(ax(i));
                obj.handles.(image_h{i}) = imagesc(d.after{1},'Parent',ax(i));
                set(ax(i),'XTick',[],'YTick',[]);
                daspect(ax(i),[1 1 1]);

                hold(ax(i),'on');
                obj.handles.(roi_h{i}) = plot(ax(i), roi_x, roi_y, 'g', 'HitTest', 'off');
            end
            
            obj.handles.display_tracked_roi = plot(obj.handles.image_ax, roi_x, roi_y, 'r', 'HitTest', 'off');
            
            z = zeros(size(d.after{1}));
            obj.handles.mask_image = image(z,'AlphaData',z,'Parent',obj.handles.image_ax);
            

            % Get centre of roi and stabalise using optical flow
            roi = d.roi.x + 1i * d.roi.y;
            p = mean(roi);
            obj.tracked_roi_centre = TrackJunction(obj.data.flow,p) - p;

            
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
            
            cur_image = double(obj.data.after{cur});
            cur_image =  cur_image / prctile(cur_image(:),99);
            out_im = repmat(cur_image,[1 1 3]);
            out_im(out_im > 1) = 1;
            
            mask_im = zeros(size(cur_image));
            
            ndil = 4;
            
            cmap = [0 0 0
                    1 0 0
                    0 1 0
                    0 0 1];
                        
            for i=1:length(obj.junctions)
                tp = obj.junctions(i).tracked_positions;
                if ~isempty(tp)
                    [~,idx] = GetThickLine(size(cur_image),tp(cur,:),600,ndil); 
                    mask_im(idx) = obj.junctions(i).type;
                end
            end
            
            obj.handles.image.CData = out_im;
            
            obj.handles.mask_image.CData = ind2rgb(mask_im+1,cmap);
            obj.handles.mask_image.AlphaData = 0.8*(mask_im>0);
            
            d = obj.data;
            
            offset = obj.tracked_roi_centre(cur);
            set(obj.handles.display_tracked_roi,'XData',d.roi.x+real(offset),...
                                                'YData',d.roi.y+imag(offset));
                        
        end
        
        function recovery = GetRecovery(obj,opt)
            d = obj.data;

            roi = d.roi.x + 1i * d.roi.y;
            if nargin > 1 && strcmp(opt,'stable')
                % Get centre of roi and stabalise using optical flow
                [~,~,recovery] = ExtractRecovery(d.before, d.after, roi, obj.tracked_roi_centre); 
            else
                [~,~,recovery] = ExtractRecovery(d.before, d.after, roi);
            end
        end
        
        function StartNewJunction(obj, junction_type)
            j = Junction(obj.handles.draw_ax,junction_type);
            
            if isempty(obj.junctions)  
                obj.junctions = j;
            else
                obj.junctions(end+1) = j;
            end

            obj.draw_mode = 'new_junction';
    
            obj.UpdateKymographList();
        end

        function UpdateKymographList(obj)           
            names = cell(size(obj.junctions));
            for i=1:length(obj.junctions)
                names{i} = ['Junction ' num2str(i) ' (' obj.junction_types{obj.junctions(i).type} ' junction)'];
            end
            obj.handles.kymograph_select.String = names;
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
                    
            end
        end

        function p = GetCurrentPoint(obj)
            pt = get(obj.handles.draw_ax, 'CurrentPoint');
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
            junctions{obj.current_index} = obj.junctions; %#ok
            save(save_name,'junctions');
        end
        
        function [jcns, save_name] = LoadJunctions(obj)
            [path, file] = fileparts(obj.reader.file);
            save_name = [path filesep file '-junctions.mat'];
            jcns = {};
            if exist(save_name,'file')
                j = load(save_name);
                if isfield(j,'junctions')
                    jcns = j.junctions;
                end
            end
        end
        
        function TrackJunction(obj, j)
            np = 50;
            p = obj.junctions(j).positions;
            t = TrackJunction(obj.data.flow, p, true, np);
            nb = length(obj.data.before);
            t = [repmat(t(1,:),[nb 1]); t];

            obj.junctions(j).tracked_positions = t;
        end

        function TrackJunctions(obj)
                       
            wh = waitbar(0, 'Tracking Junctions...');
            for i=1:length(obj.junctions)
                obj.TrackJunction(i);
                waitbar(i/length(obj.junctions));
            end
            close(wh);
            
        end
        
        function UpdateKymograph(obj)
           
            junction = obj.handles.kymograph_select.Value;
            [kymograph,r] = GenerateKymograph(obj, junction);
            
            t = 1:size(kymograph,2);
            
            distance_label = ['Distance (' obj.data.length_unit ')'];
            
            ax_h = obj.handles.kymograph_ax;
            imagesc(t,r,kymograph,'Parent',ax_h);
            ax_h.TickDir = 'out';
            ax_h.Box = 'off';
            xlabel(ax_h,'Time (frames)');
            ylabel(ax_h,distance_label);
            
            lim = 500;
            
            
            r = r / obj.data.px_per_unit;
            contrast = ComputeKymographOD_GLCM(r,kymograph,lim);
            
            h_ax = obj.handles.od_glcm_ax;
            plot(obj.handles.od_glcm_ax,contrast);
            xlabel(h_ax,distance_label);
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
            
            for i=1:length(obj.junctions)
                kymograph = obj.GenerateKymograph(i);
                filename = [obj.data.name '_junction_' num2str(i) '_' obj.junction_types{obj.junction_type(i)} '.tif'];
                imwrite(kymograph,[export_folder filesep filename]);
            end
            
        end
        
        function [kymograph,r] = GenerateKymograph(obj, j)
            
            if ~obj.junctions(j).IsTracked()
                obj.TrackJunction(j);
            end

            p = obj.junctions(j).tracked_positions;
            
            images = [obj.data.before, obj.data.after];

            options.line_width = 9;

            results = ExtractTrackedJunctions(images, {p}, options);
            [kymograph,r] = GetCorrectedKymograph(results);

        end
        
    end
    
end