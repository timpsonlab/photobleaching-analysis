function corrected = CompensateDrift(frames,options)

    if nargin < 2
        options = struct();
    end
    
    if ~isfield(options,'frame_binning')
        options.frame_binning = 1;
    end

    sz = size(frames{1});    
    padded_sz = 2.^nextpow2(sz);
    
    % Choose every frame_binning frames
    n = length(frames);
    frame_idx = [1:options.frame_binning:(n-1) n];
    sel_frames = frames(frame_idx);

    % Precompute FFT of each frame
    parfor i=1:length(sel_frames)
        fr = sel_frames{i};
        pad = padded_sz-sz;
        fr = padarray(fr,pad,0,'post');
        fft_frames{i} = fft2(single(fr)); 
    end
        
    % Make pairs of images so we can compute shifts in parallel
    a = circshift(fft_frames,[0 1]);
    a = [a; fft_frames]; 
    
    upsampling = 5;
    parfor i=2:length(fft_frames)
        ai = a(:,i);
        output(:,i) = dftregistration(ai{2},ai{1},upsampling);        
    end
    
    % Assemble shifts
    shift_x = -cumsum(output(4,:));
    shift_y = -cumsum(output(3,:));
    
    % Interpolate shifts to every frame
    shift_x = interp1(frame_idx,shift_x,1:n,'spline');
    shift_y = interp1(frame_idx,shift_y,1:n,'spline');

    % Apply computed shifts 
    corrected = cell(size(frames));
    corrected{1} = frames{1};
    
  %{
    nr = padded_sz(1);
    nc = padded_sz(2);
    Nr = ifftshift((-fix(nr/2):ceil(nr/2)-1))/nr;
    Nc = ifftshift((-fix(nc/2):ceil(nc/2)-1))/nc;
    [Nc,Nr] = meshgrid(Nc,Nr);
  %}
  
    view = imref2d(size(frames{1}));
    parfor i=2:length(frames)
        tform = affine2d();
        tform.T(3,1) = shift_x(i);
        tform.T(3,2) = shift_y(i);
        
        corrected{i} = imwarp(frames{i},tform,'OutputView',view,'FillValues',nan);

        %phase = 2*pi*(shift_x(i)*Nr+shift_y(i)*Nc);
        %corrected{i} = real(ifft2(fft_frames{i}.*exp(1i*phase)));
        %corrected{i} = corrected{i}(1:sz(1),1:sz(2));
    end
    
end