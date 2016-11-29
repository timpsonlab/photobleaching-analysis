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
        name = arrayfun(@(x) char(m.getImageName(x-1)), 1:n_image, 'UniformOutput', false);

        % Match FRAP group and series 
        tokens = regexp(name,'(FRAP.*)\/(.+)','tokens');
        matched = cellfun(@(x) ~isempty(x), tokens);

        matched_idx = 1:n_image;
        matched_idx = matched_idx(matched);

        group = cellfun(@(x) x{1}{1}, tokens(matched), 'UniformOutput', false);
        series = cellfun(@(x) x{1}{2}, tokens(matched), 'UniformOutput', false);

        % Get unique groups
        [obj.groups,~,group_id] = unique(group);

        % Determine which groups fufill all the required critera
        has_two_series = arrayfun(@(x) sum(group_id==x)==2, 1:length(obj.groups));

        first_series = matched_idx(arrayfun(@(x) find(group_id==x,1), 1:length(obj.groups)));
        has_roi = arrayfun(@(x) m.getImageROIRefCount(x), first_series);
        
        valid = has_two_series & has_roi;
        
        obj.groups = obj.groups(valid);
        
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
    
    function frap = GetGroup(obj,g,channel)
        
        if nargin < 3
            channel = 1;
        end
        
        matching_id = find(strcmp(obj.group,g)) - 1;
        
        im = cell([1,2]);
        for i=1:2 % we know there are two matching ids
            
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
        
        s = matching_id(1);
        
        px_size = obj.meta.getPixelsPhysicalSizeX(s);        
        dt = obj.meta.getPixelsTimeIncrement(s);
        
        if isempty(dt)
            if isfinite(dt_leica)
                dt = dt_leica;
            else
                dt = 1;
            end
        end
        
        frap.images = [im{1}; im{2}];
        frap.units_per_px = double(px_size.value);
        frap.length_unit = char(px_size.unit.getSymbol);
        frap.dt = dt;
        frap.name = obj.group{s+1};
        frap.n_prebleach_frames = length(im{1});
        
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