function SaveVideo(filename, F)
% SaveVideo Convenience wrapper for VideoWriter
%   Saves the images in cell array F to a video 'filename'
%   Tested with avi

    writerObj = VideoWriter(filename);
    writerObj.Quality = 100;
    open(writerObj);
    for j=1:length(F)
        writeVideo(writerObj,im2frame(F{j}))
    end
    close(writerObj);

end