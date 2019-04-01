function kymograph = LoadKymograph(filename)
    kymograph = [];

    info = imfinfo(filename);

    if info.ImageDescription(1) ~= '{'
        kymograph = [];
        return
    end

    meta = loadjson(info.ImageDescription);

    if ~isfield(meta,'Kymograph')
        return
    end

    kymograph = meta.Kymograph;
    kymograph.data = imread(filename,'Info',info);
    kymograph.file = filename;
    [~,kymograph.name] = fileparts(filename);
end