% Process all FRAP stacks in a folder
% Expects folder to conform to structure documented in README.txt
% 
% Load ROI from exported leica .roi files
% Uses roi stabalisation 
%
function ProcessFRAP(roi_folder)

folder = dir(roi_folder);
folder = folder(3:end);

if isempty(folder)
    FeedbackMessage('GarvanFrap',['No folders found in: ' roi_folder],'Error');
    return
end

sel = [folder.isdir];
group_name = folder(sel).name;
folder = [roi_folder filesep group_name filesep];

subfolders = dir([folder 'FRAP_*']);
isdir = [subfolders.isdir];
subfolders = subfolders(isdir);
subfolders = {subfolders.name};

figure(10);

for i=1:length(subfolders)
        
    frap = LoadFRAPData(folder, subfolders{i});
     
    roi_x = frap.roi_x;
    roi_y = frap.roi_y;
    
    if isempty(roi_x)
        disp('Cannot process without ROI');
        continue
    end
    
    px = mean(roi_x);
    py = mean(roi_y);
    roi_x = (roi_x - px) * 1;
    roi_y = (roi_y - py) * 1;
    
    [px,py] = TrackJunction(frap.flow,px,py);
    
    t1 = [];
    t2 = [];
    
    sz = size(frap.before{1});
    
    [X,Y] = meshgrid(1:sz(2),1:sz(1));
    mask1 = inpolygon(X,Y,roi_x+px(1),roi_y+py(1));

    se = strel('disk',3);
    mask3 = imdilate(mask1,se);

    for j=1:length(frap.before)
        initial(j) = sum(frap.before{j}(mask1));
    end

    initial = mean(initial);
    F = {};
    
    FeedbackMessage('GarvanFrap','   Generating movie...');

    
    for j=1:length(frap.after)
        im = frap.after{j};
        out_im = GetGreenMappedImage(im);

        p = [[roi_x roi_x(1)]' + px(1) [roi_y roi_y(1)]' + py(1)]';
        out_im = insertShape(out_im, 'Polygon', p(:)', 'Color', 'b', 'LineWidth', 1);

        p = [[roi_x roi_x(1)]'+ px(j) [roi_y roi_y(1)]' + py(j)]';
        out_im = insertShape(out_im, 'Polygon', p(:)', 'Color', 'r', 'LineWidth', 1);
        
        out_im(out_im > 1) = 1;
        out_im(out_im < 0) = 0;
        out_im(~isfinite(out_im)) = 0;

        out_im = permute(out_im,[2 1 3]);

        %out_im = AddScaleBar(out_im, 1/px_per_um, 5, 10);

        F{j} = out_im;
        
        mask2 = inpolygon(X,Y,roi_x+px(j),roi_y+py(j));
        mask3 = imdilate(mask2,se);

        t1(j) = sum(im(mask1));
        t2(j) = sum(im(mask2));
        
        image(out_im);
        daspect([1 1 1])
        drawnow;
    end
    
    SaveVideo([folder '..' filesep subfolders{i} '.avi'], F)
    
    t1 = t1 / initial;
    t2 = t2 / initial;
    
    plot([t1; t2]');
    ylabel('Intensity');
    xlabel('Frame #');
    legend({'Untracked', 'Tracked'});
    drawnow;
    
    csvwrite([folder '..' filesep subfolders{i} ' recovery.csv'],[t1; t2]');
    
    
    
end