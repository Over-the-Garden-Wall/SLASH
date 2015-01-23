function create_training_example(cube_number, object_number)

    tic; disp('begin');

    if ~exist('object_number', 'var')
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
    
    imSz = [256 256 256];
    
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
   
    
    [seg, initial_condense] = condense_im(seg, all_segs);
    
    new_in_segs = initial_condense(in_segs);
    num_segs = length(all_segs);
    seg_is_in = false(num_segs,1);
    seg_is_in(new_in_segs) = true;
    
%     disp(find(seg_is_in));
    
    edge_mat = zeros(num_segs+1, num_segs+1, 7); %total aff, min aff, max aff, count, edge_num
    edge_mat(:,:,2) = Inf;
    
    
%     toc
%     tic; disp('115 loop');
    
    nhood = -eye(3);
    for x = 2:imSz(1)
        for y = 2:imSz(2)
            for z = 2:imSz(3)
                id1 = seg(x,y,z);
                for n = 1:3
                    id2 = seg(x+nhood(n,1), y+nhood(n,2), z+nhood(n,3));
                    edge_mat(id1+1, id2+1, 1) = edge_mat(id1+1, id2+1, 1) + aff(x,y,z,n);
                    edge_mat(id1+1, id2+1, 2) = min(edge_mat(id1+1, id2+1, 2), aff(x,y,z,n));
                    edge_mat(id1+1, id2+1, 3) = max(edge_mat(id1+1, id2+1, 3), aff(x,y,z,n));
                    edge_mat(id1+1, id2+1, 4) = edge_mat(id1+1, id2+1, 4) + 1;
                    edge_mat(id1+1, id2+1, 5) = edge_mat(id1+1, id2+1, 5) + (x+nhood(n,1)/2)/imSz(1)*4-2;
                    edge_mat(id1+1, id2+1, 6) = edge_mat(id1+1, id2+1, 6) + (y+nhood(n,2)/2)/imSz(2)*4-2;
                    edge_mat(id1+1, id2+1, 7) = edge_mat(id1+1, id2+1, 7) + (z+nhood(n,3)/2)/imSz(3)*4-2;
                end
            end
        end
    end
    
%     disp(size(edge_mat));
    
%     edge_mat(:,:,1) = edge_mat(:,:,1) + edge_mat(:,:,1)';
    edge_mat(:,:,2) = min(cat(3, edge_mat(:,:,2), edge_mat(:,:,2)'), [], 3);
    edge_mat(:,:,3) = max(cat(3, edge_mat(:,:,3), edge_mat(:,:,3)'), [], 3);
    for k = [1 4:7]
        edge_mat(:,:,k) = edge_mat(:,:,k) + edge_mat(:,:,k)';
    end
    
    edge_mat = edge_mat(2:end, 2:end, :);
    
    
    toc
%     tic; disp('150 loop');
    

    
    
    
    
    
    is_good_edge = (edge_mat(:,:,4)>0) & (seg_is_in *ones(1,length(seg_is_in)) | ones(length(seg_is_in),1)*seg_is_in');
    is_good_edge = triu(is_good_edge);
    good_edge_list = find(is_good_edge(:));
    [xs ys] = ind2sub(size(is_good_edge), good_edge_list);

    num_edges = length(good_edge_list);
    
    edge_data.total = zeros(num_edges,1);
    edge_data.min = zeros(num_edges,1);
    edge_data.max = zeros(num_edges,1);
    edge_data.count = zeros(num_edges,1);
    edge_data.com = zeros(num_edges,3);
    edge_data.members = zeros(num_edges,2);
    edge_data.is_correct = false(num_edges,1);
    
%     disp(['start t loop, edges: ' num2str(num_edges)]);
    
    for t = 1:num_edges
        x = xs(t);
        y = ys(t);
        
        edge_data.total(t) = edge_mat(x,y,1);
        edge_data.min(t) = edge_mat(x,y,2);
        edge_data.max(t) = edge_mat(x,y,3);
        edge_data.count(t) = edge_mat(x,y,4);
        edge_data.members(t,:) = [x y];
        edge_data.com(t,:) = squeeze(edge_mat(x,y,5:7))/edge_data.count(t);
        edge_data.is_correct(t) = seg_is_in(x) && seg_is_in(y);
    end
    
    
%     for x = 1:size(edge_mat,1)
% %         disp(x)
%         for y = x+1:size(edge_mat,2)
%             if edge_mat(x,y,4)>0 && (seg_is_in(x) || seg_is_in(y))
% %                 disp([x y seg_is_in(x) seg_is_in(y)]);
%                 num_edges = num_edges+1;
%                 edge_data{num_edges}.total = edge_mat(x,y,1);
%                 edge_data{num_edges}.min = edge_mat(x,y,2);
%                 edge_data{num_edges}.max = edge_mat(x,y,3);
%                 edge_data{num_edges}.count = edge_mat(x,y,4);
%                 edge_data{num_edges}.members = [x y];
%                 edge_data{num_edges}.com = squeeze(edge_mat(:,:,5:7))/edge_data{num_edges}.count;
%                 edge_data{num_edges}.is_correct = seg_is_in(x) && seg_is_in(y);
%             end
%         end
%     end
                    
%     disp('loop done');
    
    in_and_adjacent_segs = unique( edge_data.members(:));
    
%     disp('condensing')
%     save('../debug.mat','lbl', 'seg', 'aff', 'new_in_segs', 'edge_data', 'edge_mat');
    [seg remap] = condense_im(seg, in_and_adjacent_segs);
    
%         disp('remapping')
    
        edge_data.members = remap(edge_data.members);
    
        original_ids = all_segs(in_and_adjacent_segs);
    num_segs = length(in_and_adjacent_segs);
    
    coeffs = coefficient_powers(3, C.moment_depth_generation);
    
    
%     disp(coeffs)


    
%     toc
%     tic; disp('200 loop');
%     
%     segments = cell(num_segs,1);
%     for n = 1:num_segs
%         segments{n}.moments = zeros(size(coeffs,1),1);
%         segments{n}.size = 0;
%         segments{n}.original_id = original_ids(n);
%     end
    
    segments.moments = zeros(num_segs, size(coeffs,1));
    segments.size = zeros(num_segs, 1);
    segments.original_id = zeros(num_segs, 1);
    segments.is_in = false(num_segs,1);
    
        
    for x = 1:imSz(1)
        for y = 1:imSz(2)
            for z = 1:imSz(3)
                if seg(x,y,z) ~= 0
                    k = seg(x,y,z);
                    
                    segments.moments(k,:) = segments.moments(k,:) + ...
                        ((x/imSz(1)*4-2).^coeffs(:,1) .* (y/imSz(2)*4-2).^coeffs(:,2) .* (z/imSz(3)*4-2).^coeffs(:,3))';
                    segments.size(k) = segments.size(k) + 1;
                end
            end
        end
    end
    
    newer_in_segs = remap(new_in_segs);
    segments.is_in(newer_in_segs) = true;
    
    toc
    save([C.training_dir ...
        '/cube_' num2str(cube_number(1)) '_' num2str(cube_number(2)) '_' num2str(cube_number(1)), ...
        '_object' num2str(object_number)], 'segments', 'edge_data');
       
    disp('end');
%     save('../debug.mat','lbl', 'seg', 'aff', 'segments', 'edge_data');
    
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
