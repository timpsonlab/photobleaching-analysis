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
    
    if kymograph.temporal_units_per_pixel == 0
        kymograph.temporal_units_per_pixel = 1;
    
    end
    
    %{
    k = kymograph.data;
    sz = size(k);
    k = reshape(k,[sz(1) 4 sz(2)/4]);
    k = sum(k,2);
    k = squeeze(k);
    kymograph.data = k;
    %}
end