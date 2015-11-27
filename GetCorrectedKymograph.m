function [l2,r] = GetCorrectedKymograph(Rx)

    l2 = [];
    n = size(Rx.l2,1);
    
    for k=1:size(Rx.l2,3)
        for i=1:size(Rx.l2,2)

            x = (0:(n-1)) * Rx.R2(i,k);
            X = (0:(n-1)) * Rx.R2(1,k);

            y = Rx.l2(:,i,k);
            Y = interp1(x,y,X);

            l2(:,i,k) = Y;
        end
    end
    
    r = repmat((0:(n-1))',[1 size(Rx.R2,2)]) .* repmat(Rx.R2(1,:), [n, 1]);
    