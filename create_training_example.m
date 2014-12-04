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
    us_loc(end+1) = find(vol_fn == '.', 1, 'first');
    
    vol_coords = [str2double(vol_fn(us_loc(1)+2:us_loc(2)-1)), ...
        str2double(vol_fn(us_loc(2)+1:us_loc(3)-1)), ...
        str2double(vol_fn(us_loc(3)+1:us_loc(4)-1)); ...
        str2double(vol_fn(us_loc(4)+2:us_loc(5)-1)), ...
        str2double(vol_fn(us_loc(5)+1:us_loc(6)-1)), ...
        str2double(vol_fn(us_loc(6)+1:us_loc(7)-1))];
        
    lbl = get_label(vol_coords);
    aff = get_affinity(vol_coords);
%     save('../debug.mat','lbl', 'seg', 'aff');
    
    
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
    [nhood(:,1), nhood(:,2), nhood(:,3)] = ind2sub([3 3 3], 1:27);
    nhood = nhood - 2;
    
    lbl_bin = lbl == object_number;
    
    for k = 1:size(nhood,1)
        lbl_code((2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1)) = ...
            lbl_code((2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1), (2:end-1) + nhood(k,1)) + ...
            lbl_bin;
    end
    
    lbl_code = lbl_code(2:end-1, 2:end-1, 2:end-1);
    
    all_segs = unique(seg(:));
    all_segs(all_segs==0) = [];
    
    
    in_segs = unique(seg(lbl_code == size(nhood,1)));
    in_segs(in_segs==0) = [];
    disp(in_segs);
    
    [seg, initial_condense] = condense_im(seg, all_segs);
    
    new_in_segs = initial_condense(in_segs);
    num_segs = length(all_segs);
    seg_is_in = false(num_segs,1);
    seg_is_in(new_in_segs) = true;
    
    disp(num_segs);
    
    edge_mat = zeros(num_segs+1, num_segs+1, 5); %total aff, min aff, max aff, count, edge_num
    
    
    nhood = -eye(3);
    for x = 2:256
        for y = 2:256
            for z = 2:256
                id1 = seg(x,y,z);
                for n = 1:3
                    id2 = seg(x+nhood(n,1), y+nhood(n,2), z+nhood(n,3));
                    edge_mat(id1+1, id2+1, 1) = edge_mat(id1+1, id2+1, 1) + aff(x,y,z,n);
                    edge_mat(id1+1, id2+1, 2) = min(edge_mat(id1+1, id2+1, 2), aff(x,y,z,n));
                    edge_mat(id1+1, id2+1, 3) = max(edge_mat(id1+1, id2+1, 3), aff(x,y,z,n));
                    edge_mat(id1+1, id2+1, 4) = edge_mat(id1+1, id2+1, 4) + 1;
                end
            end
        end
    end
    
    
    for k = 1:4;
        edge_mat(:,:,k) = edge_mat(:,:,k) + edge_mat(:,:,k)';
    end
    edge_mat = edge_mat(2:end, 2:end, :);
    
    
    
    
    edge_data = cell(10000,1);    
    num_edges = 0;
    for x = 1:size(edge_mat,1)
%         disp(x)
        for y = x+1:size(edge_mat,1)
            if seg_is_in(x) || seg_is_in(y)
                if edge_mat(x,y,5) == 0
                    num_edges = num_edges+1;
                    edge_mat(x,y,5) = num_edges;
                    my_id = num_edges;
                else
                    my_id = edge_mat(x,y,5);
                end
                edge_data{my_id}.total = edge_mat(x,y,1);
                edge_data{my_id}.min = edge_mat(x,y,2);
                edge_data{my_id}.max = edge_mat(x,y,3);
                edge_data{my_id}.count = edge_mat(x,y,4);
                edge_data{my_id}.members = [x y];
            end
        end
    end
                    
    edge_data = edge_data(1:num_edges);
    
    
    disp(new_in_segs)
    in_and_adjacent_segs = find(any(edge_mat(new_in_segs,:,4)));
    
    disp(num_edges)
    
%     save('../debug.mat','lbl', 'seg', 'aff', 'new_in_segs', 'edge_data', 'edge_mat');
    [seg remap] = condense_im(seg, in_and_adjacent_segs);
    
    for k = 1:num_edges
        disp(edge_data{num_edges}.members)
        edge_data{num_edges}.members = remap(edge_data{num_edges}.members);
    end
    original_ids = all_segs(in_and_adjacent_segs);
    num_segs = length(in_and_adjacent_segs);
    
    coeffs = [];
    for k = 1:C.moment_depth_generation
        kcoeffs = [];
        [kcoeffs(:,1), kcoeffs(:,2), kcoeffs(:,3)] = ind2sub((1+k)*ones(1,3), 1:(k+1)^3);
        kcoeffs = kcoeffs-1;
        kcoeffs = kcoeffs(sum(kcoeffs,2)==k,:);
        coeffs = [coeffs; kcoeffs];
    end
    
    
    disp(num_segs)
    
    segments = cell(num_segs,1);
    for n = 1:num_segs
        segments{n}.moments = zeros(size(coeffs,1),1);
        segments{n}.size = 0;
        segments{n}.original_id = original_ids(n);
    end
        
    for x = 1:256
        for y = 1:256
            for z = 1:256
                if seg(x,y,z) ~= 0
                    k = seg(x,y,z);
                    
                    segments{k}.moments = segments{k}.moments + ...
                        (x-128.5)^coeffs(:,1) + (y-128.5)^coeffs(:,2) + (z-128.5)^coeffs(:,3);
                    segments{k}.size = segments{k}.size + 1;
                end
            end
        end
    end
    
    save('../debug.mat','lbl', 'seg', 'aff', 'segments', 'edge_data');
    
end

function im = omniwebcube2im(im)
    im = reshape(im, [128 128 128 2 2 2]);
    im = permute(im, [1 4 2 5 3 6]);
    im = reshape(im, [256 256 256]);
end

function [im, seg_order] = condense_im(im, values)
    
    max_val = max(values);
    seg_order = zeros(max_val,1);
    
    for k = 1:length(values)        
        seg_order(values(k)) = k;
    end
    
    for k = 1:numel(im)
        if im(k) > 0
            if im(k) <= max_val
                im(k) = seg_order(im(k));            
            else
                im(k) = 0;
            end
        end
    end
end
