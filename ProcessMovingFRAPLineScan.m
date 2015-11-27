function results = ProcessMovingFRAPLineScan(frap, initial_x, initial_y, lines)

    if nargin < 4
        lines = 1:length(initial_x);
    end

    n = length(lines);
    np = 600;
        
    after = frap.after;
    before = frap.before;
    sz = size(after{1});
    
    tracked_points_file = [frap.folder frap.subfolder filesep 'tracked points.mat'];
    
    if ~exist(tracked_points_file,'file')
        for i=1:n
            [line_x{i},line_y{i}] = TrackJunction(frap.flow,initial_x{i},initial_y{i});
        end
        save(tracked_points_file,'line_x','line_y');
    else
        l = load(tracked_points_file);
        line_x = l.line_x;
        line_y = l.line_y;
    end
        
    for i=1:n
        [X1{i},Y1{i}] = GetSpline(line_x{i}(1,:),line_y{i}(1,:),np,'linear');
        I1{i} = sub2ind(sz,round(Y1{i}),round(X1{i}));
    end
        
    kern = fspecial('disk',3);
        
    n_frame = length(before)+length(after);
    
    l1 = zeros(np,n_frame,n);
    l2 = zeros(np,n_frame,n);
    R1 = zeros(n_frame,n);
    R2 = zeros(n_frame,n);
    
    cmap = gray(255);
    cmap(:,1) = 0;
    cmap(:,3) = 0;
    
    F = cell(1,n_frame);
    NF = cell(1,n_frame);
    
    idx = 1;
    
    for j=1:length(before)
        processFrame(before{j});
    end
    for j=1:length(after)
        processFrame(after{j});
    end
    
    
    function processFrame(im)
        imc = conv2(double(im),kern,'same');
        
        total(idx) = sum(im(:));
        
        out_im = GetGreenMappedImage(im);
        
        native_im = out_im;
        ndil = 4;

        col = [1,0,0; 
               0,0,1;
               0,0,1;
               1,0.5,0;
               1,0.5,0;
               1,0,0;
               1,0,0;
               1,0,0];
        
        for k=lines
            [X,Y] = GetSpline(line_x{k}(j,:),line_y{k}(j,:),np,'linear');        

            g = -diff(Y) + 1i * diff(X);
            g = g ./ abs(g);
            g = [g(1); g];
            
            g = repmat(g, [1 2*ndil+1]);            
            g = g .* repmat(-ndil:ndil, [np 1]);
            
            XW = repmat(X, [1 2*ndil+1]) + real(g);
            YW = repmat(Y, [1 2*ndil+1]) + imag(g);
            
            XW = max(round(XW),1);
            XW = min(XW,size(im,2));
            YW = max(round(YW),1);
            YW = min(YW,size(im,1));
            
            
            I = sub2ind(size(im),YW,XW);
            
            R1(idx,k) = abs((X1{k}(2)-X1{k}(1)) + 1i*(Y1{k}(2)-Y1{k}(1)));
            R2(idx,k) = abs((X(2)-X(1)) + 1i*(Y(2)-Y(1)));

            l1(:,idx,k) = imc(I1{k});
            l2(:,idx,k) = sum(im(I),2);
            
            
            I2 = sub2ind(size(im),round(YW),round(XW));
            mask = false(size(ims));
            mask(I2) = true;
            
            se = strel('disk',2);
            mask = imdilate(mask,se);
            mask = imerode(mask,se);
            
            for m = 1:3
                maskm = false(size(out_im));
                maskm(:,:,m) = mask;
                out_im(maskm) = 0.2 * out_im(maskm) + 0.8 * col(k,m);
            end
                        
            % Add initial stripe
            %p = [initial_x{k}' initial_y{k}']';
            %out_im = insertShape(out_im, 'Line', p(:)', 'Color', 'g','LineWidth',2);
            
            % Add text
            %idx = round(np/2);
            %out_im = insertText(out_im, [X(idx) Y(idx)],num2str(k),...
            %    'AnchorPoint','Center','BoxColor','red','TextColor','white','FontSize',12);
            
            
        end

        p = [[frap.roi_x frap.roi_x(1)]' [frap.roi_y frap.roi_y(1)]']';
        out_im = insertShape(out_im, 'Polygon', p(:)', 'Color', 'w', 'LineWidth', 4);
        native_im = insertShape(native_im, 'Polygon', p(:)', 'Color', 'w', 'LineWidth', 4);
        
        out_im(out_im > 1) = 1;
        out_im(out_im < 0) = 0;
        out_im(~isfinite(out_im)) = 0;

        native_im(native_im > 1) = 1;
        native_im(native_im < 0) = 0;
        native_im(~isfinite(native_im)) = 0;

        native_im = permute(native_im,[2 1 3]);
        out_im = permute(out_im,[2 1 3]);

        %out_im = AddScaleBar(out_im, 1/px_per_um, 5, 10);

        F{idx} = [native_im; out_im];
        NF{idx} = out_im;
        idx = idx + 1;
    end
    
    results = struct('l1',l1,...
                     'l2',l2,...
                     'R1',R1,...
                     'R2',R2,...
                     'F',F,...
                     'NF',NF,...
                     'total',total,...
                     'px_per_um',frap.px_per_um);
                     
end
