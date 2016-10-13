classdef FrapTool < handle

    properties
        fh;
        handles;
        
        reader;
        
        datasets;
        current_index;
        data;
        last_folder;
                        
        junction_artist;
        
        rois;
        tracked_roi_centre;
        
        lh;
                
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
                                   
            obj.UpdateDatasetList();
        end
        
        function UpdateDatasetList(obj)
           obj.handles.files_list.String = obj.reader.groups;
           obj.handles.files_list.Value = 1;
        end
        
       
        
        function UpdateDisplay(obj)
            cur = round(obj.handles.image_scroll.Value);
            
            cur_image = double(obj.data.after{cur});
            cur_image =  cur_image / prctile(cur_image(:),99);
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
                    mask_im(idx) = jcns.type;
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

        function UpdateKymographList(obj)           
            names = obj.junction_artist.GetJunctionNames();
            obj.handles.kymograph_select.String = names;
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
            recovery_tracked = GetRecovery(obj,'stable');

            dat = table();
            dat.T = (0:length(recovery_untracked)-1)';
            dat.Tracked = recovery_tracked';
            dat.Untracked = recovery_untracked';
            
            writetable(dat,[export_folder filesep obj.data.name '_recovery.csv']);
            
        end
        
        function [kymograph,r] = GenerateKymograph(obj, j)
            
            jcn = obj.junction_artist.junctions(j);
            
            if ~jcn.IsTracked()
                obj.TrackJunction(j);
            end

            p = jcn.tracked_positions;
            
            images = [obj.data.before, obj.data.after];

            options.line_width = 9;

            results = ExtractTrackedJunctions(images, {p}, options);
            [kymograph,r] = GetCorrectedKymograph(results);

        end
        
    end
    
end