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
            h.channel_popup.Callback = @(~,~) obj.SwitchDataset(h.files_list.Value);
            h.delete_roi_button.Callback = @(~,~) obj.DeleteRoi();
            h.roi_type_popup.Callback = @obj.ChangeRoiType;
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
                warndlg('Please load data first','Could not estimate photobleaching');
                return;
            end
            
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
            
            if isempty(roi_dist) 
                obj.SetRoiSelection('roi',roi_idx);
            elseif isempty(junction_dist)
                obj.SetRoiSelection('junction',junction_idx);
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

            if strcmp(type,'roi')
            
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
            
            if nargin > 2 && strcmp(opt,'stable')
                % Get centre of roi and stabalise using optical flow
                recovery = d.roi(idx).tracked_recovery;
            else
                recovery = d.roi(idx).untracked_recovery;
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
            
            initial = mean(corrected(1:obj.data.n_prebleach_frames));
            corrected = corrected / initial;

            t = (0:size(recovery,1)-1)' * obj.data.dt;
        end
        
        function [all_recoveries, t] = GetAllRecoveries(obj,opt)
            d = obj.data;
            
            if nargin < 2
                opt = '';
            end

            all_recoveries = [];
            
            sel = strcmp({d.roi.type},'Recovery');
            idx = 1:length(d.roi);
            idx = idx(sel);
            for i=idx
                [recovery, t] = obj.GetRecovery(i,opt);
                all_recoveries = [all_recoveries recovery]; %#ok
            end
                        
        end

        function UpdateKymographList(obj)           
            names = obj.junction_artist.GetJunctionNames();
            obj.handles.kymograph_select.String = names;
        end
        
        function UpdateRecoveryCurves(obj)
            rec_h = obj.handles.recovery_ax;
            cla(rec_h);
            
            if strcmp(obj.selection_type,'roi')
                
                [recovery1,t] = obj.GetRecovery(obj.selected_roi); 
                recovery2 = obj.GetRecovery(obj.selected_roi,'stable');
                recovery = [recovery1 recovery2];
                
            else
                
                results = obj.GetCorrectedKymograph(obj.selected_roi);
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
            t = TrackJunction(obj.data.flow, p, true, np);
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
        
    end
    
end