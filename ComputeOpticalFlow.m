function flow = ComputeOpticalFlow(ims, options)
% ComputeOpticalFlow Compute optical flow between a series of images
%
%    Wrapper for OpticalFlow from Vision Toolbox
%    ims: cell array of images to compute flow between
%    image_smoothing_kernel_width: smoothing to apply to images before analysis 
%    flow_smoothing_kernel_width: smoothing to apply to computed flow   
% 
%    See Also vision.OpticalFlow

    % Setup default options
    if nargin < 2
        options = struct;
    end
    if ~isfield(options,'image_smoothing_kernel_width')
        options.image_smoothing_kernel_width = 5;
    end
    if ~isfield(options,'flow_smoothing_kernel_width')
        options.flow_smoothing_kernel_width = 8;
    end
    if ~isfield(options,'frame_binning')
        options.frame_binning = 1;
    end
      
    % Downsample images
    n = length(ims);
    n = ceil(n/options.frame_binning);
    downsampled = zeros([size(ims{1}), n]);
    idx = 1;
    for i=1:n
        for j=1:options.frame_binning
            if (idx < length(ims))
                downsampled(:,:,i) = downsampled(:,:,i) + double(ims{idx});
            end
            idx = idx + 1;
        end
    end
    
    % Apply smoothing to images
    if options.image_smoothing_kernel_width > 1
        kern = fspecial('disk',options.image_smoothing_kernel_width);
        parfor i=1:n
            downsampled(:,:,i) = conv2(downsampled(:,:,i),kern,'same');
        end
    end
    
    % Setup smoothing kernel
    kern = fspecial('disk', options.flow_smoothing_kernel_width);
    use_smoothing = options.flow_smoothing_kernel_width > 1;
   
    % Split up the data
    poolobj = gcp(); % If no pool, do not create new one.
    poolsize = poolobj.NumWorkers;
    lflow_all = cell([1 poolsize]);
    pool_data = cell([1 poolsize]);
    
    disp(['Pool size: ' num2str(poolsize)]);

    m = ceil(n / poolsize);
    for q=1:poolsize
       offset = (q-1) * m;
       range = (1:(m+1))+offset;
       range = range(range <= n);
       pool_data{q} = downsampled(:,:,range); 
    end  
    
    % Compute optical flow    
    parfor q=1:poolsize
        data = pool_data{q};
        sz = size(data);
        m = sz(3) - 1;
        lflow = zeros([sz(1:2) m]);

        optical = opticalFlowHS();
        estimateFlow(optical,double(data(:,:,1)));
        for i=1:m
            f = estimateFlow(optical, double(data(:,:,i+1)));
            lflow(:,:,i) = f.Vx + 1i * f.Vy;
            if use_smoothing
                lflow(:,:,i) = conv2(lflow(:,:,i), kern, 'same');    
            end
        end
        lflow_all{q} = lflow;
    end
    
    % Put the data back together
    flow = zeros(size(ims{1}));
    for q=1:poolsize
        flow = cat(3,flow,lflow_all{q});
    end
    flow = single(flow);
    flow = repmat(flow,[1 1 1 options.frame_binning]);
    flow = permute(flow,[1 2 4 3]);
    sz = size(flow);
    flow = reshape(flow,[sz(1:2) prod(sz(3:4))]);
    flow = flow(:,:,1:length(ims)) / options.frame_binning;