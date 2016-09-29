function flow = ComputeOpticalFlow(ims, image_smoothing_kernel_width, flow_smoothing_kernel_width)
% ComputeOpticalFlow Compute optical flow between a series of images
%
%    Wrapper for OpticalFlow from Vision Toolbox
%    ims: cell array of images to compute flow between
%    image_smoothing_kernel_width: smoothing to apply to images before analysis 
%    flow_smoothing_kernel_width: smoothing to apply to computed flow   
% 
%    See Also vision.OpticalFlow

    if nargin < 2
        image_smoothing_kernel_width = 5;
    end
    if nargin < 3
        flow_smoothing_kernel_width = 8;
    end

    optical = OpticalFlowLK();

    % Apply smoothing to images
    if image_smoothing_kernel_width > 0
        kern = fspecial('disk',image_smoothing_kernel_width);
        for i=1:length(ims)
            ims{i} = conv2(double(ims{i}),kern,'same');
        end
    end
    
    % Compute optical flow
    flow = zeros(size(ims{1}));
    step(optical,double(ims{1}));
    for i=2:length(ims)
        flow(:,:,i) = step(optical, double(ims{i}));
        kern = fspecial('disk', flow_smoothing_kernel_width);
        if flow_smoothing_kernel_width > 0
            flow(:,:,i) = conv2(flow(:,:,i), kern, 'same');    
        end
    end
    
    flow = single(flow);
    