function points = LoadJunctionPoints(folder, subfolder)
% LoadJunctionPoints Load saved junction points 
%   Load saved junction points from FRAP movie in [folder subfolder]
%   If no points are saved, prompt user to draw points
%
%   See also DrawJunctions 

    points_file = [folder subfolder filesep 'points.mat'];
    if ~exist(points_file,'file')
        DrawJunctions(frap,[folder subfolder filesep]);
    end
    
    points = load(points_file);
    
    % Convert old points file
    if ~iscell(points.x)
        points.x = {points.x};
        points.y = {points.y};
    end
    
    sel = cellfun(@isempty,points.x);
    points.x = points.x(~sel);
    points.y = points.y(~sel);

end