function results = GenerateKymographsFromFRAPStack(root, always_request_new_points)
% GenerateKymographsFromFRAPStack
%    Generate Kymographs from all FRAP/FLIP movies in the folder root
%    The folder root should be structured as described in README.txt
%
%    Will prompt user to draw junctions if they haven't already been
%    created. If always_request_new_points is set to true, will prompt 
%    the user to draw new junctions even if they already exist. 
%
%    For FLIP movies, by convention the junctions should be drawn in the 
%    following order:
%
%    1:   Bleached junction
%    2,3: Juntions adjacent to the bleach region
%    4-8: Distant junctions (4,5 are required)


if nargin < 1
    root = uigetdir();
    root = [root filesep];
end

if nargin < 2
    always_request_new_points = false;
end

% Get all FRAP movies 
[folder,subfolders] = GetFRAPSubFolders(root);

% Get junctions from user (if they don't already exist)
FeedbackMessage('GarvanFrap',['Processing: ' folder]);
for i=1:length(subfolders)
    FeedbackMessage('GarvanFrap',['   > ' subfolders{i}]);

    points_file = [folder subfolders{i} filesep 'points.mat'];
    if ~exist(points_file,'file') || always_request_new_points
        frap = LoadFRAPData(folder, subfolders{i});
        DrawJunctions(frap,[folder subfolders{i} filesep]);
    end
    
end
FeedbackMessage('GarvanFrap','Got all junctions...')
results = {};


for i=1:length(subfolders)
    
    % Load FRAP data and get points on junctions
    frap = LoadFRAPData(folder, subfolders{i});
    points = LoadJunctionPoints(folder, subfolders{i});
    
    
    results{i} = ProcessMovingFRAPLineScan(frap, points.x, points.y);
              
    results{i} = struct('l1',l1,'l2',l2,'R1',R1,'R2',R2,'total',total,'folder',folder,'subfolder',subfolders{i});
    
    avi_out_file = [folder '..' filesep subfolders{i} '-tracking.avi'];
    SaveVideo(avi_out_file, F);

    mat_out_file = [folder subfolders{i} filesep 'line recovery.mat'];
    r = results{i};
    save(mat_out_file,'-struct','r');
end

FeedbackMessage('GarvanFrap','Complete!')
