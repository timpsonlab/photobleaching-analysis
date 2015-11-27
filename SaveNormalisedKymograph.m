function SaveNormalisedKymograph(im, r, rout, filename)
    
    cmap = hot(255);
    
    dt = 1.621;    
    t = ((1:size(im,2))-1) * dt;

    [T,R]=meshgrid(t,r);
    [TOUT,ROUT]=meshgrid(t,rout);
    im = interp2(T,R,im,TOUT,ROUT);

    im = round(im / max(im(:)) * 255);
    im(im>255) = 255;
    im = ind2rgb(im,cmap);

    im = imresize(im,[size(im,1) size(im,2)*2],'nearest');
    
    imagesc(t,rout,im)
    set(gca,'TickDir','out');

    imwrite(im,filename);
