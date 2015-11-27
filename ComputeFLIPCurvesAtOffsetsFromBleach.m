function results = ComputeFLIPCurvesAtOffsetsFromBleach(frap, initial_x, initial_y, R, offsets_um, radius_um)
%
% Compute FLIP curves at a certain number of offsets along a junction
% specified by points initial_x and initial_y from a point specified by the
% centre of the FRAP roi.
% 
% Photobleaching correction is performed using the distant tracked junction
% in R
%
    if nargin < 5
        offsets_um = [-3, -1.5, 0, 1.5, 3];
    end
    if nargin < 6
        radius_um = 0.5;
    end
    
    % Get initial points for bleached junction and stabalise from flow
    initial_x = initial_x{1};
    initial_y = initial_y{1};
    [line_x,line_y] = TrackJunction(frap.flow, initial_x, initial_y);
    
    after = frap.after;
    before = frap.before;
    sz = size(after{1});
        
    roi_x = frap.roi_x;
    roi_y = frap.roi_y;
    
    % Get centre of bleach region
    bleach_c_x = mean(roi_x);
    bleach_c_y = mean(roi_y);
    
    points = offsets_um * frap.px_per_um;
    [IX,IY] = meshgrid(1:sz(2),1:sz(1));

    r2 = (radius_um * frap.px_per_um)^2;
    
    line_x = [line_x(1,:); line_x];
    line_y = [line_y(1,:); line_y];
    
    frames = [before(end) after];
    
    for j=1:length(frames)
        
        total(j) = mean(frames{j}(:));
        
        [X,Y] = GetSpline(line_x(j,:),line_y(j,:),250,'linear');      
    
        dr = sqrt((X(2)-X(1)).^2 + (Y(2)-Y(1)).^2);
        
        dist2 = (X-bleach_c_x).^2 + (Y-bleach_c_y).^2;
        [~,idx] = min(dist2);

        p_idx = round(points / dr + idx);
        p_idx = max(p_idx,1);
        p_idx = min(p_idx,length(X));
        
        BX = X(p_idx);
        BY = Y(p_idx);   
        
        for k=1:length(points)
            mask = (IX - BX(k)).^2 + (IY - BY(k)).^2 < r2;
            region(j,k) = mean(frames{j}(mask));
        end
        
    end
    
    % Correct for photobleaching using 'distant' junctions
    % by convention these are junctions 4 and 5
    distant = R.l2(:,5:end,4:5);
    distant = nanmean(distant,1);
    distant = nanmean(distant,3)';
    x = 1:length(distant);
    fitresult = FitExpWithPlateau(x,distant);
    pb = feval(fitresult,x);
    
    fitmodel = FitExpWithPlateau(1:length(pb),pb);
    pb_curve = feval(fitmodel,1:length(total));
    pb_curve = pb_curve / pb_curve(1);

    distant = distant / distant(1);
    distant = distant ./ pb_curve;
    
    pb_curve_rep = repmat(pb_curve,[1 5]);
    region = region ./ pb_curve_rep;
    
    results = struct('region',region,'total',total,'distant',distant);
    
end
