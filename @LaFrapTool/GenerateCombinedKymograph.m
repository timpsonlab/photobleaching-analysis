function [r,t,kymograph,n] = GenerateCombinedKymograph(obj)

    cur = obj.handles.files_list.Value;
    distance = str2double(obj.handles.distance_edit.String);
    max_time = str2double(obj.handles.max_time_edit.String);
    n = 600;
    
    rc = linspace(-distance/2,distance/2,n);
    
    combined_kymograph = 0;
    combined_norm = 0;
       
    for i=1:length(cur)
       
        kymograph = obj.kymographs(cur(i));
        
        ki = kymograph.data;
        ri = (0:size(ki,1)-1) * kymograph.spatial_units_per_pixel;
        ti = (0:size(ki,2)-1) * kymograph.temporal_units_per_pixel;

        % Crop kymograph
        n = kymograph.n_prebleach_frames;
        ti = ti - n * kymograph.temporal_units_per_pixel;
        ti_final = ti(ti < max_time);

        % Compute before and after sections
        before = mean(ki(:,1:n),2); 
        after = mean(ki(:,(n+1):2*n),2); 
        
        % Estimate centre of bleach region
        bleach = after ./ before;
    
        kern_width = 2 * sqrt(kymograph.roi_area / pi); % diameter of bleach
        kern_width = kern_width / kymograph.spatial_units_per_pixel;
        kern_width = 50;
        
        kern = ones(1,2*ceil(kern_width));
                
        %ki = ki ./ nanmean(before);
        ki = ki ./ before;
     
        bleach = conv(bleach,kern,'valid');
        
        [~,min_loc] = min(bleach);
        min_loc = min_loc + length(kern)/2; % we only use 'valid' part of kern
        
        zero_point = ri(min_loc);
        
%        zero_point = max(ri) * kymograph.roi_intersection; % saved as fraction
        ri = ri - zero_point;

        % Interpolate kymograph to grid 
        kii = interp2(ti,ri',ki,ti_final,rc');
        
        % Combine valid parts of kymograph
        combined_norm = combined_norm + ~isnan(kii);
        kii(isnan(kii)) = 0;
        combined_kymograph = combined_kymograph + kii;
        
    end
    
    kymograph = combined_kymograph ./ combined_norm;
    r = rc;
    t = ti_final;

end