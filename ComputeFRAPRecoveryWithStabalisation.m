function ComputeFRAPRecoveryWithStabalisation(folder, subfolder)
% Process all FRAP stacks in a folder
% Expects folder to conform to structure documented in README.txt
% 
% Load ROI from exported leica .roi files
% Uses roi stabalisation 
%
 
    set(gcf,'Name',[folder ' ' subfolder]);
    
    frap = LoadFRAPData(folder, subfolder);
     
    roi_x = frap.roi_x;
    roi_y = frap.roi_y;
    
    if isempty(roi_x)
        FeedbackMessage('GarvanFrap','Cannot process without ROI','Error');
        return;
    end
    
    % Get centre of roi and stabalise using optical flow
    px = mean(roi_x);
    py = mean(roi_y);
    roi_x = (roi_x - px) * 1;
    roi_y = (roi_y - py) * 1;

    [px,py] = TrackJunction(frap.flow,px,py);
    

    recovery_static = [];
    recovery_tracked = [];
    
    sz = size(frap.before{1});
    
    [X,Y] = meshgrid(1:sz(2),1:sz(1));
    mask1 = inpolygon(X,Y,roi_x+px(1),roi_y+py(1));

    % Compute initial itensity
    initial = zeros(size(frap.before));
    for j=1:length(frap.before)
        initial(j) = sum(frap.before{j}(mask1));
    end
    initial = mean(initial);
    
    F = {};
    for j=1:length(frap.after)
        im = frap.after{j};
        out_im = GetGreenMappedImage(im);

        p = [[roi_x roi_x(1)]' + px(1) [roi_y roi_y(1)]' + py(1)]';
        out_im = insertShape(out_im, 'Polygon', p(:)', 'Color', 'blue', 'LineWidth', 1);

        p = [[roi_x roi_x(1)]'+ px(j) [roi_y roi_y(1)]' + py(j)]';
        out_im = insertShape(out_im, 'Polygon', p(:)', 'Color', 'red', 'LineWidth', 1);
        
        out_im(out_im > 1) = 1;
        out_im(out_im < 0) = 0;
        out_im(~isfinite(out_im)) = 0;

        out_im = permute(out_im,[2 1 3]);
        %out_im = AddScaleBar(out_im, 1/px_per_um, 5, 10);

        F{j} = out_im;

        mask2 = inpolygon(X,Y,roi_x+px(j),roi_y+py(j));

        recovery_static(j) = sum(im(mask1));
        recovery_tracked(j) = sum(im(mask2));
        
        image(out_im);
        daspect([1 1 1])
        drawnow;
    end
    
    SaveVideo([folder '..' filesep subfolder '.avi'], F);
    
    recovery_static = recovery_static / initial;
    recovery_tracked = recovery_tracked / initial;
    
    plot([recovery_static; recovery_tracked]')
    drawnow;
    
    csvwrite([folder '..' filesep subfolder ' recovery.csv'],[recovery_static; recovery_tracked]');
    
end