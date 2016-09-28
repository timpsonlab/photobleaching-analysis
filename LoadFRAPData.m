function [frap,cache_file] = LoadFRAPData(folder, subfolder)
% LoadFRAPData Load photobleaching data from file  
%    Expects data to be organised as described in README.txt
%    Caches data for faster subsequent load
%    
%    This function may need to be modified for other FRAP data formats
% 
%    Caches can be invalidated by changing the version number 'v'

    % Search string for pre-bleach images
    pre_bleach_magic_string = '*Pre*'; 
    
    % Search string for registered post-bleach images 
    post_bleach_registered_magic_string = '*Pb1-reg*';
    
    % Search string for unregistered post-bleach images, used if no
    % registered images are found
    post_bleach_magic_string = '*Pb1*';

    v = 4;
    root = [folder subfolder filesep];
    cache_file = [root subfolder 'FRAPData.mat'];
    
    FeedbackMessage('GarvanFrap',['Loading FRAP Data from: ' folder subfolder])
    
    % Load Cached file, if it exists
    if exist(cache_file,'file')
        ver = load(cache_file,'v');
        if ~isfield(ver,v) || ver.v >= v
            FeedbackMessage('GarvanFrap','   Found valid cache file; loading...')
            frap = load(cache_file);
            frap.folder = folder;
            frap.subfolder = subfolder;
            return;
        else
            FeedbackMessage('GarvanFrap','   Found old cache file; ignoring.');
        end  
    else
        FeedbackMessage('GarvanFrap','   No cache file found; loading from file.');
    end
         
    % Otherwise, load data from disk
    FeedbackMessage('GarvanFrap','   Loading files...')
    [before, px_per_um] = LoadImagesFromFolder(pre_bleach_magic_string);  
    after = LoadImagesFromFolder(post_bleach_magic_string);
    if isempty(after)
        FeedbackMessage('GarvanFrap','   Could not find registered images; loading originals');
        after = LoadImagesFromFolder(post_bleach_registered_magic_string);
    end
    
    % Load Leica ROI file
    % You will need to modify this section for other microscope formats
    image_width_px = size(before{1},1);
    image_width_um = image_width_px / px_per_um;
    
    mask_search_string = [folder '..' filesep strrep(subfolder,'_','') '*.roi'];
    mask_file = dir(mask_search_string);
    
    if ~isempty(mask_file)
        mask_name = mask_file(1).name;
        [roi_x,roi_y] = GetPointsFromLeicaRoiFile([folder '..' filesep mask_name], image_width_px, image_width_um);
    else
        FeedbackMessage('GarvanFrap',['   No ROI file found searching in: ' mask_search_string]);
        roi_x = [];
        roi_y = [];
    end
    
    FeedbackMessage('GarvanFrap','   Computing optical flow...');
    flow = ComputeOpticalFlow(after);
    
    % Load data into a structure and save to disk
    frap = struct();
    frap.before = before;
    frap.after = after;
    frap.flow = flow;
    frap.roi_x = roi_x;
    frap.roi_y = roi_y;
    frap.folder = folder;
    frap.subfolder = subfolder;
    frap.px_per_um = px_per_um;
    frap.v = v;
 
    save(cache_file,'-struct','frap');
    
    function [images, px_per_um] = LoadImagesFromFolder(search)
    % Load a series of numbered images from a folder
    % Preferentially choose files with magic string
    
        magic_string = '*ch00';
        sel_folder = dir([root search]);
               
        if isempty(sel_folder)
            images = {};
            px_per_um = 1;
            return 
        end
        
        sel_folder = sel_folder(1).name;
       
        files = dir([root sel_folder filesep magic_string '.tif']); 
        
        if isempty(files)
            files = dir([root sel_folder filesep '*.tif']); 
        end
        
        files = {files.name};
        
        % Assumes resolution is correctly stored in files in px per cm (standard tif format)
        info = imfinfo([root sel_folder filesep files{1}]);
        px_per_um = info.XResolution / 1e4;
        
        images = cellfun(@(file) imread([root sel_folder filesep file]), files, 'UniformOutput', false);
    end
    
    FeedbackMessage('GarvanFrap','Finished Loading.')

end