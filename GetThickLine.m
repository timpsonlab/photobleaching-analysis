function [X,Y,IDX] = GetThickLine(sz,line_x,line_y,np,ndil)
    [X,Y] = GetSpline(line_x,line_y,np,'linear');        

    g = -diff(Y) + 1i * diff(X);
    g = g ./ abs(g);
    g = [g(1); g];

    g = repmat(g, [1 2*ndil+1]);            
    g = g .* repmat(-ndil:ndil, [np 1]);

    XW = repmat(X, [1 2*ndil+1]) + real(g);
    YW = repmat(Y, [1 2*ndil+1]) + imag(g);

    XW = max(round(XW),1);
    XW = min(XW,sz(2));
    YW = max(round(YW),1);
    YW = min(YW,sz(1));
    
    IDX = sub2ind(sz,YW,XW);
end