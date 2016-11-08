classdef FrapTool < handle

    properties
        fh;
        handles;
        
        roi_handler;
        selected_roi;
        reader;
        
        datasets;
        current_index;
        data;
        last_folder;
                        
        junction_artist;
                
        lh;
        
        pb_model;          
    end
   
    
    methods
        function obj = FrapTool

            addpath('layout');
            GetBioformats();

            obj.SetupLayout();
            obj.SetupMenu();
            obj.SetupCallbacks();
                        
            if ispref('FrapTool','last_folder')
                obj.last_folder = getpref('FrapTool','last_folder');
            end
                        
            obj.lh = addlistener(obj.junction_artist,'JunctionsChanged',@(~,~) obj.UpdateKymographList);
        end
        
        function delete(obj)
            delete(obj.roi_handler);
        end
        
        function set.last_folder(obj,value)
            if ischar(value)
                obj.last_folder = value;
                setpref('FrapTool','last_folder',value);
            end
        end
        
        function AddRoi(obj)
            roi = obj.roi_handler.roi;
            
            if ~isempty(roi) && isa(roi,'Roi')
                roi = roi.Track(obj.data.flow);
                obj.data.roi(end+1) = roi;
                obj.selected_roi = length(obj.data.roi);
            end
            
            obj.UpdateRecoveryCurves();
            obj.UpdateDisplay();
            
        end
        
        function SetupMenu(obj)
            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) obj.LoadData,'Accelerator','O');
            uimenu(file_menu,'Label','Refresh','Callback',@(~,~) obj.SetCurrent,'Accelerator','R');
            uimenu(file_menu,'Label','Export Recovery Curves...','Callback',@(~,~) obj.ExportRecovery,'Separator','on');
            uimenu(file_menu,'Label','Export Recovery Curves for all Datasets...','Callback',@(~,~) obj.ProcessAll);
            uimenu(file_menu,'Label','Export Kymographs...','Callback',@(~,~) obj.ExportKymographs,'Separator','on');

            tracking_menu = uimenu(obj.fh,'Label','Tracking');
            uimenu(tracking_menu,'Label','Track Junctions...','Callback',@(~,~) obj.TrackJunctions,'Accelerator','T');
        end
        
        function SetupCallbacks(obj)
            h = obj.handles;
            h.files_list.Callback = @(list,~) obj.SwitchDataset(list.Value);
            h.reload_button.Callback = @(~,~) obj.SwitchDataset(h.files_list.Value);
            h.estimate_photobleaching_button.Callback = @(~,~) obj.EstimatePhotobleaching();
            h.photobleaching_popup.Callback = @(~,~) obj.UpdateRecoveryCurves();
            h.recovery_popup.Callback = @(~,~) obj.UpdateRecoveryCurves();

            obj.roi_handler = RoiHandler(h);
            addlistener(obj.roi_handler,'roi_updated',@(~,~) obj.AddRoi);
        end
        
        
        function LoadData(obj,root)
            
            if (nargin < 2)
                [file, root] = uigetfile('*.*','Choose File...',obj.last_folder);
            end
            if file == 0
                return
            end
            
            obj.fh.Name = ['FRAP Analysis - ' root file];

            obj.last_folder = root;
            obj.reader = FrapDataReader([root file]);
            pause(0.1);  
            obj.UpdateDatasetList();
            obj.SwitchDataset(1);
            
            obj.handles.photobleaching_status.ForegroundColor = 'r';
            obj.handles.photobleaching_status.String = 'None Loaded';
            obj.handles.photobleaching_popup.Enable = 'off';
            obj.handles.photobleaching_popup.Value = 1;
            
        end
        
        function UpdateDatasetList(obj)
           obj.handles.files_list.String = obj.reader.groups;
           obj.handles.files_list.Value = 1;
        end
        
        function EstimatePhotobleaching(obj)
           
            if isempty(obj.data)
                warndlg('Please load data first');
                return;
            end
                        
            d = obj.data;
            idx = obj.selected_roi;
            p = d.roi(idx).position;
            [recovery, initial] = ExtractRecovery(d.before, d.after, p); 

            recovery = recovery / mean(initial);
            
            obj.pb_model = FitExpWithPlateau((0:length(recovery)-1)',double(recovery));
            % = feval(fitmodel,1:length(mean_after));

            obj.handles.photobleaching_status.ForegroundColor = 'g';
            obj.handles.photobleaching_status.String = 'Loaded';
            obj.handles.photobleaching_popup.Enable = 'on';
            obj.handles.photobleaching_popup.Value = 2;
            
            obj.UpdateRecoveryCurves();
        end
        
        
        function UpdateDisplay(obj)
            
            cur = round(obj.handles.image_scroll.Value);

            image1 = double(obj.data.after{1});
            
            cur_image = double(obj.data.after{cur});
            cur_image =  cur_image / prctile(image1(:),99);
            out_im = repmat(cur_image,[1 1 3]);
            out_im(out_im > 1) = 1;
            
            mask_im = zeros(size(cur_image));
            
            ndil = 4; % TODO
            
            cmap = [0 0 0
                    1 0 0
                    0 1 0
                    0 0 1];
                        
            jcns = obj.junction_artist.junctions;
            for i=1:length(jcns)
                tp = jcns(i).tracked_positions;
                if ~isempty(tp)
                    [~,idx] = GetThickLine(size(cur_image),tp(cur,:),600,ndil); 
                    mask_im(idx) = jcns(i).type;
                end
            end
            
            obj.handles.image.CData = out_im;
            
            obj.handles.mask_image.CData = ind2rgb(mask_im+1,cmap);
            obj.handles.mask_image.AlphaData = 0.8*(mask_im>0);
                        
            [x,y] = obj.data.roi.GetCoordsForPlot(cur);
            set(obj.handles.display_tracked_roi,'XData',x,'YData',y);

            [x,y] = obj.data.roi.GetCoordsForPlot(1);
            set(obj.handles.display_frap_roi,'XData',x,'YData',y);

            if ~isempty(obj.selected_roi) && obj.selected_roi <= length(obj.data.roi)
                [x,y] = obj.data.roi(obj.selected_roi).GetCoordsForPlot(cur);
                set(obj.handles.selected_tracked_roi,'XData',x,'YData',y);
            end
            
        end

        function DisplayMouseDown(obj)
           
            pt = get(obj.handles.image_ax, 'CurrentPoint');
            p = pt(1,1) + 1i * pt(1,2);
            
            % get closest ROI
            dist = arrayfun(@(x) min(abs(x.position-p)), obj.data.roi);
            [~,idx] = min(dist);

            obj.selected_roi = idx;
            
            obj.UpdateDisplay();
            obj.UpdateRecoveryCurves();
            
        end
        
        function [recovery, t] = GetRecovery(obj,idx,opt)
            d = obj.data;
            
            p = d.roi(idx).position;
            if nargin > 2 && strcmp(opt,'stable')
                % Get centre of roi and stabalise using optical flow
                [recovery, initial] = ExtractRecovery(d.before, d.after, p, d.roi(idx).tracked_offset); 
            else
                [recovery, initial] = ExtractRecovery(d.before, d.after, p);
            end

            initial_intensity = mean(initial);

            if ~isempty(obj.pb_model) && obj.handles.photobleaching_popup.Value == 2
                pb_curve = feval(obj.pb_model,0:length(recovery)-1);
                recovery = recovery ./ pb_curve;
            end

            recovery = [initial; recovery];
            recovery = recovery / initial_intensity;
            
            t = (0:size(recovery,1)-1)' * d.dt;
            
        end
        
        function [all_recoveries, t] = GetAllRecoveries(obj,opt)
            d = obj.data;
            
            if nargin < 2
                opt = '';
            end

            all_recoveries = [];
            
            for i=1:length(d.roi)
                recovery = obj.GetRecovery(i,opt);
                all_recoveries = [all_recoveries recovery]; %#ok
            end
            
            t = (0:size(recovery,1)-1)' * d.dt;
            
        end

        function UpdateKymographList(obj)           
            names = obj.junction_artist.GetJunctionNames();
            obj.handles.kymograph_select.String = names;
        end
        
        function UpdateRecoveryCurves(obj)
            rec_h = obj.handles.recovery_ax;
            cla(rec_h);
            
            idx = obj.selected_roi;
            recovery = [obj.GetRecovery(idx) obj.GetRecovery(idx,'stable')];
            
            
            plot(rec_h,recovery);
            ylim(rec_h,[0 1.2]);
            xlabel(rec_h,'Time (frames)');
            ylabel(rec_h,'Intensity');

        end
        
        function TrackJunction(obj, j)
            
            np = 50;
            p = obj.junction_artist.junctions(j).positions;
            t = TrackJunction(obj.data.flow, p, true, np);
            nb = length(obj.data.before);
            t = [repmat(t(1,:),[nb 1]); t];

            obj.junction_artist.junctions(j).tracked_positions = t;
            
        end

        function TrackJunctions(obj)
                       
            n = length(obj.junction_artist.junctions);
            wh = waitbar(0, 'Tracking Junctions...');
            for i=1:n
                obj.TrackJunction(i);
                waitbar(i/n);
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
           
            obj.TrackJunctions();
            
            export_folder = uigetdir(obj.last_folder);
            if export_folder == 0
                return;
            end
            
            jcns = obj.junction_artist.junctions;
            for i=1:length(jcns)
                kymograph = obj.GenerateKymograph(i);
                filename = [obj.data.name '_junction_' num2str(i) '_' Junction.types{jcns(i).type} '.tif'];
                imwrite(kymograph,[export_folder filesep filename]);
            end
            
        end
        
        function ExportRecovery(obj)
           
            export_folder = uigetdir(obj.last_folder);
            if export_folder == 0
                return;
            end
            
            recovery_untracked = GetRecovery(obj);
            [recovery_tracked,t] = GetRecovery(obj,'stable');

            dat = table();
            dat.T = t;
            dat.Tracked = recovery_tracked;
            dat.Untracked = recovery_untracked;
            
            writetable(dat,[export_folder filesep obj.data.name '_recovery.csv']);
            
        end
        
        function [kymograph,r] = GenerateKymograph(obj, j)
            
            jcn = obj.junction_artist.junctions(j);
            
            if ~jcn.IsTracked()
                obj.TrackJunction(j);
            end

            p = jcn.tracked_positions;
            
            images = [obj.data.before; obj.data.after];

            options.line_width = 9;

            results = ExtractTrackedJunctions(images, {p}, options);
            [kymograph,r] = GetCorrectedKymograph(results);

        end
        
    end
    
end