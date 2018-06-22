classdef FrapDataReader
   
  properties
     file;
     reader;
     meta; 
     
     groups;
  end
  
  properties(Access = private)
     group;
     series;      
  end
  
  methods 
     
    function obj = FrapDataReader(file)
        obj.file = file; 
        obj.reader = bfGetReader(file);
        obj.meta = obj.reader.getMetadataStore();
        m = obj.meta;
        
        % Get names of images
        n_image = m.getImageCount();
        image_id = 1:n_image;
        name = arrayfun(@(x) char(m.getImageName(x-1)), image_id, 'UniformOutput', false);
        
        % Remove path from series names, if it exists (e.g. ICS data)
        path = [fileparts(file) filesep];
        path = strrep(path,'\','/');
        name = strrep(name,path,''); 
        
        % Give series names if blank
        [~,filename,~] = fileparts(file); 
        unnamed = cellfun(@isempty, name);
        name(unnamed) = arrayfun(@(id) [filename ' ' num2str(id,'%03d')], image_id(unnamed), 'UniformOutput', false);
        

        % Match FRAP group and series 
        tokens = regexp(name,'([^/]+/)*(.+)','tokens');
        matched = cellfun(@(x) ~isempty(x), tokens);

        matched_idx = 1:n_image;
        matched_idx = matched_idx(matched);

        group = cellfun(@(x) x{1}{1}, tokens(matched), 'UniformOutput', false);
        series = cellfun(@(x) x{1}{2}, tokens(matched), 'UniformOutput', false);

        group = strrep(group,'/',' ');
        
        single_series = cellfun(@isempty,group);
        group(single_series) = series(single_series);
        
        % Get unique groups
        [obj.groups,~,group_id] = unique(group);

        % Determine which groups fufill all the required critera
        has_two_series = arrayfun(@(x) sum(group_id==x)==2, 1:length(obj.groups));

        first_series = matched_idx(arrayfun(@(x) find(group_id==x,1), 1:length(obj.groups)));
        has_roi = arrayfun(@(x) m.getImageROIRefCount(x-1), first_series);
        
        %valid = has_two_series & has_roi;
        %obj.groups = obj.groups(valid);
        
        obj.group = cell([n_image 1]);
        obj.group(matched_idx) = group;
        
    end
    
    function delete(obj)
        obj.reader.close();
    end
    
    function n_channel = GetNumChannels(obj,g)
        matching_id = find(strcmp(obj.group,g),1) - 1;
        n_channel = double(obj.meta.getChannelCount(matching_id));
    end
    
    function frap = GetGroup(obj,g,channel,first_only)
        
        if nargin < 3
            channel = 1;
        end
        if nargin < 4
            first_only = false;
        end
        
        matching_id = find(strcmp(obj.group,g)) - 1;
        
        if first_only
            use = 1;
        else
            use = 1:length(matching_id);
        end
        
        im = cell(size(use));
        for i=use % we know there are two matching ids
            
            % Activate series
            obj.reader.setSeries(matching_id(i));
            
            n_t = obj.reader.getSizeT();
            
            % Kludge for LIF files - we don't seem to get dt out correctly
            dt_leica = str2double(obj.reader.getSeriesMetadataValue('Image|LDM_Block_Sequential|ATLConfocalSettingDefinition|CycleTime'));
            if isnan(dt_leica)
                dt_leica = str2double(obj.reader.getSeriesMetadataValue('LDM_Block_Sequential|ATLConfocalSettingDefinition|CycleTime'));
            end
            if isnan(dt_leica)
                dt_leica = str2double(obj.reader.getSeriesMetadataValue('Image|Block_FRAP|LDM_Block_Sequential|ATLConfocalSettingDefinition|CycleTime'));
            end
            if isnan(dt_leica)
                dt_leica = str2double(obj.reader.getSeriesMetadataValue('Block_FRAP|LDM_Block_Sequential|ATLConfocalSettingDefinition|CycleTime'));
            end
            im{i} = cell([n_t 1]);
            
            for t=1:n_t
                idx = obj.reader.getIndex(0,channel-1,t-1);
                im{i}{t} = single(bfGetPlane(obj.reader, idx+1)); 
            end
            
        end
        
        if length(use) > 1
            n_prebleach_frames = length(im{1});
        else
            n_prebleach_frames = 1; % TODO
        end
        
        s = matching_id(1);
        
        px_size = obj.meta.getPixelsPhysicalSizeX(s);        
        dt = obj.meta.getPixelsTimeIncrement(s);
        
        if isempty(dt)
            if isfinite(dt_leica)
                dt = dt_leica;
            else
                dt = 1;
            end
        else
            dt = double(dt.value);
        end
        
        if isempty(px_size)
            length_unit = 'um';
            px_size = 1;
        else
            length_unit = char(px_size.unit.getSymbol);
            px_size = double(px_size.value);
        end
        
        frap.images = {};
        for i=use
            frap.images = [frap.images; im{i}];
        end
        
        frap.units_per_px = px_size;
        frap.length_unit = length_unit;
        frap.dt = dt;
        frap.name = obj.group{s+1};
        frap.n_prebleach_frames = n_prebleach_frames;
        
        frap.roi = obj.GetROI(s);
        
    end
    
    function roi = GetROI(obj,series)

        n_roi = obj.meta.getImageROIRefCount(series);

        roi = Roi.empty();
        for j=1:n_roi
            roi_ref = char(obj.meta.getImageROIRef(series,j-1));
            roi_id = strrep(roi_ref,'ROI:','');
            roi_id = str2double(roi_id);
                        
            roi_j = Roi();
            
            n_shape = obj.meta.getShapeCount(roi_id);
            for i=1:n_shape
                shape_type = char(obj.meta.getShapeType(roi_id,i-1));

                switch shape_type
                    case 'Polygon'

                        % Get points from polygon
                        points = char(obj.meta.getPolygonPoints(roi_id,i-1));
                        points = cellfun(@str2num,strsplit(points,' ')','UniformOutput',false);
                        points = cell2mat(points);
                        
                        roi_j = Roi(points(:,1), points(:,2));

                    case 'Ellipse'
                        
                        % TODO
                        
                    case 'Rectangle'
                        
                        x = double(obj.meta.getRectangleX(roi_id,i-1));
                        y = double(obj.meta.getRectangleY(roi_id,i-1));
                        w = double(obj.meta.getRectangleWidth(roi_id,i-1));
                        h = double(obj.meta.getRectangleHeight(roi_id,i-1));
                        
                        points_x = [x x x+w x+w];
                        points_y = [y y+h y+h y];
                        
                        roi_j = Roi(points_x,points_y);
                        
                        % TODO
                                             
                end

            end
            
            roi_j.label = roi_ref;
            roi_j.type = 'Bleached Region';
          
            if ~isempty(roi_j.position)
                roi(end+1) = roi_j;
            end
            
        end
        
    end
    
  end
    
end