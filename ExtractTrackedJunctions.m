function results = ExtractTrackedJunctions(frames, tracked_x, tracked_y)

    lines = 1:length(tracked_x);
    np = 600;
    ndil = 4;
    
    for j=1:length(frames)

        im = frames{j};

        for k=lines
            [X,Y,IDX] = GetThickLine(size(im),tracked_x{k}(j,:),tracked_y{k}(j,:),np,ndil);        
            
            R2(j,k) = abs((X(2)-X(1)) + 1i*(Y(2)-Y(1)));
            l2(:,j,k) = sum(im(IDX),2);

        end
    end
    
    results.R2 = R2;
    results.l2 = l2;
end
