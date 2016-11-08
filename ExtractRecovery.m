function [recovery,initial,complete] = ExtractRecovery(before, after, roi, p)

    if nargin < 4
        p = 0;
    end

    roi_x = real(roi);
    roi_y = imag(roi);
    
    px = real(p);
    py = imag(p);
    
    sz = size(after{1});
    [X,Y] = meshgrid(1:sz(2),1:sz(1));
    
    % Compute initial intensity
    mask = inpolygon(X,Y,roi_x+px(1),roi_y+py(1));
    initial = zeros(size(before));
    for j=1:length(before)
        initial(j) = ExtractPoly(before{j},px(1),py(1));
    end
        
    recovery = zeros(size(before));
    for j=1:length(after)
        if j <= length(p)
            ju = length(p);
        end
        recovery(j) = ExtractPoly(after{j},px(ju),py(ju));
    end
        
    complete = [initial; recovery];
   
    function v = ExtractPoly(im,px,py)
        
        rx = roi_x+px;
        ry = roi_y+py;
        
        sel = (X >= min(floor(rx))) & ...
              (X <= max(ceil(rx)))  & ...
              (Y >= min(floor(ry))) & ...
              (Y <= max(ceil(ry)));

        mask = inpoly([X(sel),Y(sel)],[rx,ry]);
        im = im(sel);
        v = sum(im(mask));
    end
    
end