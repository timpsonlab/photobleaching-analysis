function kymograph = DownsampleKymograph(kymograph, downsampling)

    ki = kymograph.data;
    sz = size(ki);
    
    t_final = floor(sz(2) / downsampling);
    
    ki = reshape(ki(:,1:t_final*downsampling),[sz(1) downsampling t_final]);
    ki = sum(ki,2);
    ki = squeeze(ki);

    kymograph.temporal_units_per_pixel = kymograph.temporal_units_per_pixel * downsampling;
    kymograph.kymograph = ki;
    
end