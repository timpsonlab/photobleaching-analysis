function WriteFPTiff(timg, filename, resolution)
% WriteFPTiff
%    Write a 64bit floating point TIFF file
%    timg: double input array
%    filename: output file
%    resolution: resolution to record in header (optional)

    if nargin < 3
        resolution = 1;
    end

    FeedbackMessage('GarvanFrap',['Writing Tiff: ' filename])
    t = Tiff(filename, 'w'); 
    tagstruct.ImageLength = size(timg, 1); 
    tagstruct.ImageWidth = size(timg, 2); 
    tagstruct.Compression = Tiff.Compression.None; 
    tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP; 
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack; 
    tagstruct.BitsPerSample = 64;
    tagstruct.SamplesPerPixel = 1; 
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
    tagstruct.XResolution = resolution;
    tagstruct.YResolution = resolution;
    
    t.setTag(tagstruct); 
    t.write(timg); 
    t.close();