function create_training_example(cube_number, object_number)

    if ~exist(object_number, 'var')
        object_number = 'rand';
        
    end
    
    C = lash_constants;
    
    vol_dir = [C.cube_dir 'x' format_num(cube_number(1),2) '/y' format_num(cube_number(2),2) '/'];
    
    disp(vol_dir);
    
    vol_files = dir(vol_dir);
    
    fn_start = ['x' format_num(cube_number(1),2) 'y' format_num(cube_number(2),2) 'z' format_num(cube_number(3),2)];
    vol_fn = [];
    for n = 1:length(vol_files);
        if length(vol_files(n).name) > length(fn_start) && strcmp(vol_files(n).name(1:length(fn_start)), fn_start)
            vol_fn = vol_files(n).name;
        end
    end
    
    disp(vol_fn);
    
    if isempty(vol_fn)
        error(['volume not found in ' vol_dir]);
    end
    
    if ~strcmp(vol_fn(end-5:end), '.files')
        vol_fn = [vol_fn '.files'];
    end
    
    segmentation_fn = [vol_dir vol_fn '/segmentations/segmentation1/0/volume.uint32_t.raw'];
    
    
    
    fid = fopen(segmentation_fn, 'r');
    seg = fread(fid,'uint32');
    fclose(fid);
    
    seg = omniwebcube2im(seg);
    
    us_loc = find(vol_fn=='_');
    us_loc(end+1) = find(vol_fn == '.', 'first');
    
    vol_coords = [str2double(vol_fn(us_loc(1)+2:us_loc(2)-1)), ...
        str2double(vol_fn(us_loc(2)+1:us_loc(3)-1)), ...
        str2double(vol_fn(us_loc(3)+1:us_loc(4)-1)); ...
        str2double(vol_fn(us_loc(4)+2:us_loc(5)-1)), ...
        str2double(vol_fn(us_loc(5)+1:us_loc(6)-1)), ...
        str2double(vol_fn(us_loc(6)+1:us_loc(7)-1))];
        
    lbl = get_label(vol_coords);
    
    lbl_ids = unique(lbl(:));
    lbl_ids(lbl_ids==0) = [];
    
    if isempty(lbl_ids)
        error('no tracing found');        
    end
    
    if strcmp(object_number, 'rand');
        object_number = lbl_ids(ceil(rand*length(lbl_ids)));
    else
        if ~any(object_number == lbl_ids)
            error('object not found in label');
        end
    end
    
    lbl_code = zeros(size(lbl)+2);
    [nhood(:,1), nhood(:,2), nhood(:,3)] = sub2ind([3 3 3], 1:27);
    nhood = nhood - 2;
    
    lbl_bin = lbl == object_number;
    
    for k = 1:size(nhood,1)
        lbl_code((2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1)) = ...
            lbl_code((2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1)) + ...
            lbl_bin;
    end
    
    lbl_code = lbl_code(2:end-1, 2:end-1, 2:end-1);
    
    in_segs = unique(seg(lbl_code == size(nhood,1)));
    out_segs = unique(seg(lbl_code > 0 & ~lbl_bin));
    
    num_in = length(in_segs);
    num_total = num_in + length(out_segs);
    
    edgemat = false(num_in, num_total);
    
    
    segments = cell(num_total,1);
    [X Y Z] = meshgrid((1:256)-128.5, (1:256)-128.5, (1:256)-128.5);
    
    for n = 1:num_total
        if n <= num_in
            segments{n}.original_ID = in_segs(n);
            segments{n}.is_in = true;
        else
            segments{n}.original_ID = out_segs(n-num_in);
            segments{n}.is_in = false;
        end
        
        is_me = seg == segments{n}.original_ID;
        x = X(is_me);
        y = Y(is_me);
        z = Z(is_me);
        
        segments{n}.moments = cell(1,C.moment_depth_generation);
        segments{n}.size = size(x,1);
            
        for k = 1:C.moment_depth_generation
            coeffs = [];
            [coeffs(:,1), coeffs(:,2), coeffs(:,3)] = ind2sub((1+k)*ones(1,3), 1:(k+1)^3);
            coeffs = coeffs-1;
            coeffs = coeffs(sum(coeffs,2)==k,:);
            num_combs = size(coeffs,1);
            
            segments{n}.moments{k}.mat = zeros(num_combs,1);
            for l = 1:num_combs
                segments{n}.moments{k}.mat(l) = sum(x.^coeffs(l,1).*y.^coeffs(l,2).*z.^coeffs(l,3));
            end
        end
            
    end
    
    
    
    
    
end

function im = omniwebcube2im(im)
    im = reshape(im, [128 128 128 2 2 2]);
    im = permute(im, [1 4 2 5 3 6]);
    im = reshape(im, [256 256 256]);
end

