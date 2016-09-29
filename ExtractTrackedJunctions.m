function results = ExtractTrackedJunctions(frames, tracked)

    lines = 1:length(tracked);
    np = 600;
    ndil = 4;
    
    for j=1:length(frames)

        im = frames{j};

        for k=lines
            [P,IDX] = GetThickLine(size(im),tracked{k}(j,:),np,ndil);        
            
            R2(j,k) = abs(P(2)-P(1));
            l2(:,j,k) = sum(im(IDX),2);

        end
    end
    
    results.R2 = R2;
    results.l2 = l2;
end
