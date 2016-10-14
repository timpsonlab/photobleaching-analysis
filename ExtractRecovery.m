function [recovery,initial,complete] = ExtractRecovery(before, after, roi, p)

    if nargin < 4
        p = zeros([1 length(after)]);
    end

    roi_x = real(roi);
    roi_y = imag(roi);
    
    px = real(p);
    py = imag(p);
    
    sz = size(after{1});
    [X,Y] = meshgrid(1:sz(2),1:sz(1));

    % Compute initial itensity
    mask = inpolygon(X,Y,roi_x+px(1),roi_y+py(1));
    initial = zeros(size(before));
    for j=1:length(before)
        initial(j) = sum(before{j}(mask));
    end
    
    recovery = zeros(size(before));
    for j=1:length(after)
        im = after{j};

        mask = inpolygon(X,Y,roi_x+px(j),roi_y+py(j));
        recovery(j) = sum(im(mask));
    end
        
    complete = [initial; recovery];