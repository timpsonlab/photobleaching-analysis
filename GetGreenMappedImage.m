function out = GetGreenMappedImage(im)

    cmap = gray(255);
    cmap(:,1) = 0;
    cmap(:,3) = 0;
    
    out = double(im);
    out = out / prctile(out(:),98) * 255;
    out = uint8(out);
    out = ind2rgb(out,cmap);
    
end