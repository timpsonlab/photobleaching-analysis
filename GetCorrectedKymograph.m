function [kymograph,r] = GetCorrectedKymograph(R)

    kymograph = zeros(size(R.l2));
    n = size(R.l2,1);
    
    for k=1:size(R.l2,3)
        for i=1:size(R.l2,2)

            x = (0:(n-1)) * R.R2(i,k);
            X = (0:(n-1)) * R.R2(1,k);

            y = R.l2(:,i,k);
            Y = interp1(x,y,X);

            kymograph(:,i,k) = Y;
        end
    end
    
    r = repmat((0:(n-1))',[1 size(R.R2,2)]) .* repmat(R.R2(1,:), [n, 1]);
    