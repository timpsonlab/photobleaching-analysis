function [P,IDX] = GetThickLine(sz,line,np,ndil)
    P = GetSplineImg(line,np,'linear');        

    g = 1i * diff(P); %-diff(imag(P)) + 1i * diff(imag(P));
    g = g ./ abs(g);
    g = [g(1); g];

    g = repmat(g, [1 2*ndil+1]);            
    g = g .* repmat(-ndil:ndil, [np 1]);

    PW = repmat(P, [1 2*ndil+1]) + g;
    PW = round(PW);
    
    XW = max(real(PW),1);
    XW = min(XW,sz(2));
    YW = max(imag(PW),1);
    YW = min(YW,sz(1));
    
    IDX = sub2ind(sz,YW,XW);
end