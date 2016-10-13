function [x,y] = GetCoordsFromRoi(roi)

    % Merge a list of ROI coordinates to plot easily

    x = nan;
    y = nan;

    for i=1:length(roi)
        if length(roi(i).x) > 1
            x = [x; roi(i).x(:); roi(i).x(1); nan];
            y = [y; roi(i).y(:); roi(i).y(1); nan];
        end
    end

end