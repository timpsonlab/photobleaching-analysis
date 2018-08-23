classdef FrapTool < handle

    properties
        fh;
        handles;
        
        roi_handler;
        
        selection_type;
        selected_roi;
        selected_junction;
        
        reader;
        
        datasets;
        current_index;
        data;
                        
        junction_artist;
                
        lh;
        
        pb_model;       
        play_timer;
    end
   
    
    methods
        function obj = FrapTool(parent, fig)

            obj.SetupLayout(parent, fig);
            obj.SetupCallbacks();
                                                
            obj.play_timer = timer('TimerFcn', @(~,~) obj.IncrementDisplay(), 'ExecutionMode','fixedRate','Period',0.025);
            
            obj.lh{1} = addlistener(obj.junction_artist,'JunctionsChanged',@(~,~) EC(@obj.UpdateKymographList));
            obj.lh{2} = addlistener(obj.handles.tab_panel,'SelectionChanged',@(~,~) EC(@obj.UpdateKymograph));
        end
        
        function delete(obj)
            delete(obj.roi_handler);
        end
               
        function menus = SetupMenu(obj)
            file_menu = uimenu(obj.fh,'Label','File');
            uimenu(file_menu,'Label','Open...','Callback',@(~,~) EC(@obj.LoadData),'Accelerator','O');
            uimenu(file_menu,'Label','Refresh','Callback',@(~,~) EC(@obj.SetCurrent),'Accelerator','R');
            uimenu(file_menu,'Label','Export Recovery Curves...','Callback',@(~,~) EC(@obj.ExportRecovery),'Separator','on');
            uimenu(file_menu,'Label','Export Recovery Curves for all Datasets...','Callback',@(~,~) EC(@obj.ProcessAll));
            uimenu(file_menu,'Label','Export Kymographs...','Callback',@(~,~) EC(@obj.ExportKymographs),'Separator','on');
            uimenu(file_menu,'Label','Export Kymographs for all Datasets...','Callback',@(~,~) EC(@obj.ExportAllKymographs));
            uimenu(file_menu,'Label','Batch Export...','Callback',@(~,~) EC(@obj.BatchExport),'Separator','on');
            uimenu(file_menu,'Label','Export for Figure...','Callback',@(~,~) EC(@obj.ExportForFigure),'Separator','on');

            tracking_menu = uimenu(obj.fh,'Label','Tracking');
            uimenu(tracking_menu,'Label','Track Junctions...','Callback',@(~,~) EC(@obj.TrackJunctions),'Accelerator','T');
            
            menus = [file_menu tracking_menu];
        end
        
        function SetupCallbacks(obj)
            h = obj.handles;
            h.files_list.Callback = @(list,~) EC(@obj.SwitchDataset,list.Value);
            h.reload_button.Callback = @(~,~) EC(@obj.SwitchDataset,h.files_list.Value);
            h.estimate_photobleaching_button.Callback = @(~,~) EC(@obj.EstimatePhotobleaching);
            h.photobleaching_popup.Callback = @(~,~) EC(@obj.UpdateRecoveryCurves);
            h.recovery_popup.Callback = @(~,~) EC(@obj.UpdateRecoveryCurves);
            h.channel_popup.Callback = @(~,~) EC(@obj.SwitchDataset,h.files_list.Value);
            h.delete_roi_button.Callback = @(~,~) EC(@obj.DeleteRoi);
            h.roi_type_popup.Callback = @(src,evt) EC(@obj.ChangeRoiType,src,evt);
            h.play_button.Callback = @(src,evt) EC(@obj.PlayButtonPressed,src,evt);
            obj.roi_handler = RoiHandler(h);
            addlistener(obj.roi_handler,'roi_updated',@(~,~) EC(@obj.AddRoi));
        end
        
        function PlayButtonPressed(obj,src,evt)
            if (src.Value)
                start(obj.play_timer)
            else
                stop(obj.play_timer)
            end
        end
        
        function IncrementDisplay(obj)
            
            v = obj.handles.image_scroll.Value + 1;
            if v > obj.handles.image_scroll.Max
                v = 1;
            end
            obj.handles.image_scroll.Value = v;
            obj.UpdateDisplay();
            
        end
        
        
        function LoadData(obj,root)
            
            if (nargin < 2)
                [file, root] = uigetfile('*.*','Choose File...',GetLastFolder(obj.fh));
            else
                [root, file, ext] = fileparts(root);
                file = [file ext];
            end
            if file == 0
                return
            end
            
            obj.fh.Name = ['FRAP Analysis - ' root file];

            SetLastFolder(obj.fh,root);
            obj.reader = FrapDataReader([root file]);
            pause(0.1);  
            
            if isempty(obj.reader.groups)
                errordlg('No FRAP datasets found!');
                return;
            end
            
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
                warndlg('Please load data first','Could not estimate photobleaching');
                return;
            end
            
            source = obj.handles.photobleaching_source_popup.Value;
            
            if source == 1 % PB regions

                sel = strcmp({obj.data.roi.type},'Photobleaching Control');
                pb_roi = obj.data.roi(sel);

                if isempty(pb_roi)
                    warndlg('Please set some ROIs to "Photobleaching Control" regions first','Could not estimate photobleaching');
                    return;
                end


                recovery = 0;
                for i=1:length(pb_roi)   
                    ri = pb_roi(i).untracked_recovery;
                    ri = ri / ri(1);
                    recovery = recovery + ri;
                end
                recovery = recovery / length(pb_roi);
                
            else % distant junctions
                
                sel = obj.junction_artist.junctions.type == 3; % bleach junction
                
                if sum(sel) == 0
                    warndlg('Please draw some distant junctions first','Could not estimate photobleaching');
                    return;
                end
                
                idx = 1:length(obj.junction_artist.junctions.type);
                idx = idx(sel);

                for i=1:length(idx)
                    results = obj.GetTrackedJunctionData(idx(i));
                    [kymograph,r] = GetCorrectedKymograph(results);
                    kymograph = nanmean(kymograph,1);
                    kymograph = kymograph / mean(kymograph(1:obj.data.n_prebleach_frames));                    
                    recovery(:,i) = kymograph;
                end
                recovery = nanmean(recovery,2);
                
            end
                
                

            obj.pb_model = FitExpWithPlateau((0:length(recovery)-1)',double(recovery));
            % = feval(fitmodel,1:length(mean_after));

            obj.handles.photobleaching_status.ForegroundColor = 'g';
            obj.handles.photobleaching_status.String = 'Loaded';
            obj.handles.photobleaching_popup.Enable = 'on';
            obj.handles.photobleaching_popup.Value = 2;
            
            obj.UpdateRecoveryCurves();
        end
        

        function DisplayMouseDown(obj)
           
            % Get click position
            pt = get(obj.handles.image_ax, 'CurrentPoint');
            p = pt(1,1) + 1i * pt(1,2);
            
            % get closest ROI
            dist = arrayfun(@(x) min(abs(x.position-p)), obj.data.roi);
            [roi_dist,roi_idx] = min(dist);
            
            % get closest junction
            dist = arrayfun(@(x) min(abs(x.positions-p)), obj.junction_artist.junctions);
            [junction_dist,junction_idx] = min(dist);
            
            if isempty(junction_dist)
                obj.SetRoiSelection('roi',roi_idx);
            elseif isempty(roi_dist) 
                obj.SetRoiSelection('roi',roi_idx);
            elseif roi_dist < junction_dist 
                obj.SetRoiSelection('roi',roi_idx);
            else
                obj.SetRoiSelection('junction',junction_idx);
            end
        end
   
%=== ROI handling ===% 
        
        function AddRoi(obj)
            roi = obj.roi_handler.roi;
            
            if ~isempty(roi) && isa(roi,'Roi')
                roi = roi.Compute(obj.data);
                roi.type = obj.handles.roi_type_popup.String{obj.handles.roi_type_popup.Value};
                obj.data.roi(end+1) = roi;
                
                obj.SetRoiSelection('roi',length(obj.data.roi));
            end
            
            obj.UpdateRecoveryCurves();
            obj.UpdateDisplay();
            
        end
        
        function DeleteRoi(obj)
           
            obj.data.roi(obj.selected_roi) = [];
            
            if isempty(obj.data.roi)
                obj.selected_roi = [];
            elseif obj.selected_roi > length(obj.data.roi)
                obj.selected_roi = length(obj.data.roi);
            end
            
            obj.UpdateDisplay();
            
        end
        
        function ChangeRoiType(obj,src,~)
            if ~isempty(obj.selected_roi)
               obj.data.roi(obj.selected_roi).type = src.String{src.Value}; 
            end
            
            obj.UpdateDisplay();
        end
        
        function RenameRoi(obj,src,~)
            if ~isempty(obj.selected_roi)
               obj.data.roi(obj.selected_roi).label = src.String; 
            end
            
            obj.UpdateDisplay();            
        end
        
        function SetRoiSelection(obj, type, idx)

            obj.selection_type = type;
            obj.selected_roi = idx;

            if strcmp(type,'roi') && ~isempty(idx)
            
                type = obj.data.roi(idx).type;
                p = find(strcmp(obj.handles.roi_type_popup.String,type),1);
                obj.handles.roi_type_popup.Value = p; 
                obj.handles.roi_name_edit.String = obj.data.roi(idx).label;
                obj.handles.roi_name_edit.Enable = 'on';
                obj.handles.delete_roi_button.Enable = 'on';
                obj.handles.roi_type_popup.Enable = 'on';
                
            else
               
                obj.handles.roi_name_edit.String = '';
                obj.handles.roi_name_edit.Enable = 'off';
                obj.handles.delete_roi_button.Enable = 'off';
                obj.handles.roi_type_popup.Enable = 'off';
                
            end
            
            obj.UpdateDisplay();
            obj.UpdateRecoveryCurves();
            
        end
        
%=== Recovery/Kymograph processing ===% 
        
        function [recovery, t] = GetRecovery(obj,idx,opt)
            d = obj.data;
            
            if nargin < 2 || isempty(idx)
                idx = 1:length(d.roi);
            end
            
            if nargin > 2 && strcmp(opt,'stable')
                % Get centre of roi and stabalise using optical flow
                recovery = [d.roi(idx).tracked_recovery];
            else
                recovery = [d.roi(idx).untracked_recovery];
            end

            [recovery,t] = obj.CorrectRecovery(recovery);
            
            
        end
        
        function pb_curve = GetPhotobleachingCorrection(obj)
            if ~isempty(obj.pb_model) && obj.handles.photobleaching_popup.Value == 2
                pb_curve = feval(obj.pb_model,0:length(obj.data.images)-1);
                pb_curve = pb_curve / pb_curve(1);
            else
                pb_curve = ones(length(obj.data.images),1);
            end           
        end
        
        function [corrected,t] = CorrectRecovery(obj,recovery)
                     
            pb_curve = obj.GetPhotobleachingCorrection();
            corrected = recovery ./ pb_curve;
            
            initial = mean(corrected(1:obj.data.n_prebleach_frames,:));
            corrected = corrected ./ initial;

            t = (0:size(recovery,1)-1)' * obj.data.dt;
        end
               
        function UpdateKymographList(obj)           
            names = obj.junction_artist.GetJunctionNames();
            obj.handles.kymograph_select.String = names;
            v = min(obj.handles.kymograph_select.Value,length(names));
            v = max(v,1);
            obj.handles.kymograph_select.Value = v;
            
            obj.UpdateKymograph();
        end
        
        function UpdateRecoveryCurves(obj)
            rec_h = obj.handles.recovery_ax;
            cla(rec_h);
            
            if strcmp(obj.selection_type,'roi')
                
                [recovery1,t] = obj.GetRecovery(obj.selected_roi); 
                recovery2 = obj.GetRecovery(obj.selected_roi,'stable');
                recovery = [recovery1 recovery2];
                
            else
                
                results = obj.GetTrackedJunctionData(obj.selected_roi);
                recovery = sum(results.l2,1)';
                
                [recovery,t] = obj.CorrectRecovery(recovery);
                                
            end
            
            plot(rec_h,t,recovery);
            ylim(rec_h,[0 1.2]);
            xlabel(rec_h,'Time (s)');
            ylabel(rec_h,'Intensity');

        end
        
        function TrackJunction(obj, j)
            
            np = 50;
            p = obj.junction_artist.junctions(j).positions;
            
            if length(p) > 1
                t = TrackJunction(obj.data.flow, p, true, np);
                obj.junction_artist.junctions(j).tracked_positions = t;
            end
            
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
            
            if junction > length(obj.junction_artist.junctions) || ...
               obj.handles.tab_panel.Selection ~= 3 % only update when we can see the kymograph 
                return;
            end
                        
            [kymograph,r] = GenerateKymograph(obj, junction);
            
            t = (0:size(kymograph,2)-1) * obj.data.dt;
            r = r * obj.data.units_per_px;
            
            distance_label = ['Distance (' obj.data.length_unit ')'];
            
            ax_h = obj.handles.kymograph_ax;
            imagesc(t,r,kymograph,'Parent',ax_h);
            ax_h.TickDir = 'out';
            ax_h.Box = 'off';
            xlabel(ax_h,'Time (s)');
            ylabel(ax_h,distance_label);
            
            lim = 500;
            
            contrast = ComputeKymographOD_GLCM(r,kymograph,lim);
            
            h_ax = obj.handles.od_glcm_ax;
            plot(obj.handles.od_glcm_ax,contrast,'-o');
            xlabel(h_ax,distance_label);
            ylabel(h_ax,'Contrast');
        end
        
        function BatchProcess(obj)
           
            options = BatchProcessingUi();
            
            if isempty(options)
                return;
            end
            
            for i=1:length(options.files)
                obj.LoadData(options.files{i});
                                
            end
            
        end
        
        function ExportKymographs(obj, export_folder)
           
            if nargin < 2
                export_folder = uigetdir(GetLastFolder(obj.fh));
            end
            if export_folder == 0
                return;
            end
            
            obj.TrackJunctions();
            
            jcns = obj.junction_artist.junctions;
            for i=1:length(jcns)
                [kymograph,r] = obj.GenerateKymograph(i);
                [closest_roi,intersection_point] = obj.FindClosestRoiToJunction(i);
                
                extra.type = jcns(i).type;
                extra.spatial_unit = obj.data.length_unit;
                extra.spatial_units_per_pixel = (r(2)-r(1)) * obj.data.units_per_px;
                extra.temporal_unit = 's';
                extra.temporal_units_per_pixel = obj.data.dt;
                extra.n_prebleach_frames = obj.data.n_prebleach_frames;

                if ~isempty(closest_roi)
                    roi = obj.data.roi(closest_roi).position * obj.data.units_per_px;
                    roi_area = polyarea(real(roi),imag(roi));
                    
                    extra.roi_intersection = intersection_point;
                    extra.roi_area = roi_area;
                    extra.roi_x = real(roi);
                    extra.roi_y = imag(roi);
                end

                extra_data = savejson('Kymograph',extra);
                                                
                tag.ImageLength = size(kymograph,1);
                tag.ImageWidth = size(kymograph,2);  
                tag.SampleFormat = Tiff.SampleFormat.IEEEFP;
                tag.Photometric = Tiff.Photometric.MinIsBlack;
                tag.BitsPerSample = 32;
                tag.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
                tag.MinSampleValue = nanmin(kymograph(:));
                tag.MaxSampleValue = nanmax(kymograph(:));
                tag.Software = 'FrapTool';
                tag.ImageDescription = extra_data;
                
                filename = [obj.data.name '_junction_' num2str(i) '_' Junction.types{jcns(i).type} '.tif'];
                t = Tiff([export_folder filesep filename], 'w');
                t.setTag(tag);
                t.write(single(kymograph));
                t.close();
            end
            
        end
        
        function ExportAllKymographs(obj,export_folder)

            if nargin < 2
                export_folder = uigetdir(GetLastFolder(obj.fh));
            end
            if export_folder == 0
                return;
            end

            stored_load_option = obj.handles.load_option_popup.Value;
            obj.handles.load_option_popup.Value = 1; % Load all data;
            
            h = waitbar(0,'Processing...');

            for i=1:length(obj.reader.groups)
                obj.SwitchDataset(i);
                obj.ExportKymographs(export_folder);

                waitbar(i/length(obj.reader.groups),h);
            end
            
            delete(h);
            
            obj.handles.load_option_popup.Value = stored_load_option;

        end
        
        function ExportRecovery(obj)
           
            export_folder = uigetdir(GetLastFolder(obj.fh));
            if export_folder == 0
                return;
            end
            
            % Region recoveries
            sel = strcmp({obj.data.roi.type},'Bleached Region');
            recovery_untracked = GetRecovery(obj,sel);
            [recovery_tracked,t] = GetRecovery(obj,sel,'stable');
                        
            headers = {obj.data.roi(sel).label};
            headers = [{'Time (s)'} headers];
            
            csvwrite_with_headers([export_folder filesep obj.data.name '_recovery_tracked.csv'], [t recovery_tracked], headers);
            csvwrite_with_headers([export_folder filesep obj.data.name '_recovery_untracked.csv'], [t recovery_untracked], headers);
            
            
            % Junction recoveries
            [junction_tracked, junction_untracked, headers] = GetAllJunctionRecoveries(obj);
            headers = [{'Time (s)'} headers];
            csvwrite_with_headers([export_folder filesep obj.data.name '_junction_recovery_tracked.csv'], [t junction_tracked],headers);
            csvwrite_with_headers([export_folder filesep obj.data.name '_junction_recovery_untracked.csv'], [t junction_untracked], headers);
            
        end
        
        function [tracked_recoveries, untracked_recoveries, headers] = GetAllJunctionRecoveries(obj)
            
            for j=1:length(obj.junction_artist.junctions)
                results = obj.GetTrackedJunctionData(j);
                kymograph = GetCorrectedKymograph(results);
                recovery = nanmean(kymograph,1);
                tracked_recoveries(:,j) = recovery;

                results = obj.GetUntrackedJunctionData(j);
                kymograph = GetCorrectedKymograph(results);
                recovery = nanmean(kymograph,1);
                untracked_recoveries(:,j) = recovery;

                name = [strtrim(obj.data.name) '_'];
                headers{j} = [name 'Junction_' num2str(j) '_' Junction.types{obj.junction_artist.junctions(j).type}];
            end

        end
        
        function [kymograph,r,results] = GenerateKymograph(obj, j)
            
            results = obj.GetTrackedJunctionData(j);
            [kymograph,r] = GetCorrectedKymograph(results);
            
            pb_curve = obj.GetPhotobleachingCorrection();
            kymograph = kymograph ./ pb_curve';

        end
        
        function results = GetTrackedJunctionData(obj, j)
            
            jcn = obj.junction_artist.junctions(j);
            
            if ~jcn.IsTracked()
                obj.TrackJunction(j);
            end

            p = jcn.tracked_positions;
            options.line_width = 9;
            results = ExtractTrackedJunctions(obj.data.images, {p}, options);
                        
        end
        
        function results = GetUntrackedJunctionData(obj, j)
            
            jcn = obj.junction_artist.junctions(j);
            
            p = jcn.positions;
            options.line_width = 9;
            results = ExtractTrackedJunctions(obj.data.images, {p}, options);
                        
        end

        
        function [closest_roi, intersection_point] = FindClosestRoiToJunction(obj, j)
           
            jcn = obj.junction_artist.junctions(j);
            
            if ~jcn.IsTracked()
                obj.TrackJunction(j);
            end

            frame_idx = obj.data.n_prebleach_frames+1;
            
            np = 600;
            p = jcn.tracked_positions(frame_idx,:); 
            p = GetSplineImg(p,np,'linear');  

            % TODO : warning if no bleach ROI found
            
            % Get ROI centres
            sel = strcmp({obj.data.roi.type},'Bleached Region');
            idx = 1:length(obj.data.roi);
            sel = idx(sel);
            
            if isempty(sel)
                closest_roi = [];
                intersection_point = [];
                return
            end
            
            for i=1:length(sel)
                roi_c(i) = mean(obj.data.roi(sel(i)).tracked_position(frame_idx));
            end
            % Get minimum distances and locations 
            [dist,loc] = arrayfun(@(x) min(abs(p-x)), roi_c);
            [~,closest_roi] = min(dist);
            
            intersection_point = (loc(closest_roi) - 1) / (np - 1);
            
        end
        
        function ExportForFigure(obj)
           
            figh = figure(100);
            clf(figh);
            
            cmap = parula(length(obj.data.images));
            color_im = 0;
            int_im = 0;
            for i=1:length(obj.data.images)
               
                im = double(obj.data.images{i}) / 256;
                color = cmap(i,:);
                color = reshape(color,[1 1 3]);
                color = repmat(color,[size(im) 1]);
                
                
                imi = im .* color;
                
                color_im = color_im + imi;
                int_im = int_im + im;
                
            end
            
            color_im = color_im / (0.5*max(color_im(:)));
            image(color_im);
            daspect([1 1 1]);
            
            r = obj.data.roi(obj.selected_roi);

            hold on;
            plot(r.position,'r-');
            
            %=====
            
            figh = figure(101);
            clf(figh);
            
            rect = [];
            
            
            padding = 15;
            x0 = floor(min(real(r.position))) - padding;
            x1 = ceil(max(real(r.position))) + padding;
            y0 = floor(min(imag(r.position))) - padding;
            y1 = ceil(max(imag(r.position))) + padding;
            
             for i=1:length(obj.data.images)
               
                im = double(obj.data.images{i}) / 256;
                
                x = round(real(r.tracked_offset(i)));
                y = round(imag(r.tracked_offset(i)));
                rect(:,:,1,i) = im((y0:y1) + y, (x0:x1) + x);
                rect_uc(:,:,1,i) = im((y0:y1), (x0:x1));
                                
             end
            
             fl = obj.data.flow((y0:y1), (x0:x1), :);
             
             sel = 1:25:length(obj.data.images);
             n = length(sel);
             
             %subplot(2,1,1)
             %montage(rect(:,:,:,sel),'Size',[1,n])
             
             %subplot(2,1,2)
             rect_uc = repmat(rect_uc,[1 1 3 1]);
             rect_uc(:,:,[1,3],:) = 0;
             
             fl = fl(:,:,sel);
             sz = size(fl);
             flm = reshape(fl,[sz(1) sz(2)*sz(3)]);
             
             sz = size(flm);
             
             nd = 10;
             x = 1:nd:sz(2);
             y = 1:nd:sz(1);
             
             flmr = imresize(real(flm),1/nd);
             flmi = imresize(imag(flm),1/nd);
             [X,Y] = meshgrid(x,y);
             
             
             montage(rect_uc(:,:,:,sel),'Size',[1,n])
             hold on;
             for i=1:length(sel)
                plot(real(r.position)+(i-1)*(x1-x0+1)-x0, imag(r.position)-y0,'w-') 
                offset = r.tracked_offset(sel(i));
                plot(real(r.position+offset)+(i-1)*(x1-x0+1)-x0, imag(r.position+offset)-y0,'r-') 
             end
             quiver(X,Y,flmr,flmi,'r');
            
            
        end
        
    end
    
end