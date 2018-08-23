function results = ExtractTrackedJunctions(frames, tracked, options)

    if nargin < 3
        options = struct();
    end

    if ~isfield(options,'line_width')
        options.line_width = 9;
    end
    
    % If we only have one set of positions use them for all
    for i=1:length(tracked)
        if size(tracked{i},1) == 1
            tracked{i} = repmat(tracked{i},[length(frames) 1]);
        end
    end

    lines = 1:length(tracked);
    spacing = 0.25;
    ndil = ceil((options.line_width-1)/2);

    for j=1:length(frames)

        im = frames{j};
        
        for k=lines
            [P,IDX] = GetThickLine(size(im),tracked{k}(j,:),spacing,ndil);        
            
            R2(j,k) = abs(P(2)-P(1));
            l2(:,j,k) = sum(im(IDX),2);

        end
    end
    
    results.R2 = R2;
    results.l2 = l2;
end
