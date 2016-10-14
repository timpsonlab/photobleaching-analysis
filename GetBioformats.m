function GetBioformats()
% Add bioformats to path.
% If required, download from OME and unzip first

    if ~exist('bfmatlab', 'dir')
        
        disp('Downloading bioformats...');
        bflink = 'http://downloads.openmicroscopy.org/bio-formats/5.2.6/artifacts/bfmatlab.zip';
        websave('bfmatlab.zip',bflink);
        unzip('bfmatlab.zip');
        delete('bfmatlab.zip');
    
    end
    
    addpath('bfmatlab')
    
end