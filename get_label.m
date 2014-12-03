function im = get_label(coords)

    C = lash_constants;

%     UPSMPL = [2 2 2];
    
    %1:256 -> 1:128
    %2:257 -> 2:129
    coords = [floor(coords(1,:)/2) + 1; ceil(coords(2,:)/2)]; 
    
    %get volume size
    fid = fopen([C.label_dir '/projectMetadata.yaml'],'r');
    
    disp([C.label_dir '/projectMetadata.yaml']);
    
    metadata = fread(fid,'char')';
    
    data_dim_spot = strfind(metadata, 'dataDimensions');
    metadata = char(metadata(data_dim_spot(1):data_dim_spot(1)+300));
    % dataDimensions: [123, 3456, 12222]
    
    spaces = find(isspace(metadata));
    imSz(1) = str2double(metadata(spaces(1)+2:spaces(2)-2));
    imSz(2) = str2double(metadata(spaces(2)+1:spaces(3)-2));
    imSz(3) = str2double(metadata(spaces(3)+1:spaces(4)-2));
    
    
    chunk_size_spot = strfind(metadata, 'chunkDim');
    metadata = metadata(chunk_size_spot(1):end);
    spaces = find(isspace(metadata));
    chunkEdge = str2double(metadata(spaces(1)+1:spaces(2)-1));
    
    fclose(fid);
    
%
%
    
    max_chunk_size = chunkEdge*ones(1,3);
    
    
%     num_chunks = ceil(imSz./max_chunk_size);
%     c = zeros(1,3);
    
    fid = fopen([C.label_dir './segmentations/segmentation1/0/volume.uint32_t.raw']);
%     fid = fopen([omni_file_dir './volume.uint32_t.raw']);
        
%     disp(num_chunks);
%     disp(max_chunk_size);
    
    disp(imSz);
    
    
    
    chunks_to_get = [floor(coords(1,:)./max_chunk_size); ...
        floor(coords(2,:)./max_chunk_size)];
    
    im = zeros((chunks_to_get(2,:) - chunks_to_get(1,:) + 1).*max_chunk_size, 'uint32');
    
    for x = chunks_to_get(1,1):chunks_to_get(2,1)
        for y = chunks_to_get(1,2):chunks_to_get(2,2)
            for z = chunks_to_get(1,3):chunks_to_get(2,3)
                s = ([x y z] - chunks_to_get(1,:)) .* max_chunk_size;                                
                im(s(1) + (1:max_chunk_size(1)), s(2) + (1:max_chunk_size(2)), s(3) + (1:max_chunk_size(3))) = ...
                    get_omni_chunk(fid, [x y z], max_chunk_size, imSz);
            end
        end
    end
                
    imr = coords - ones(2,1)*(chunks_to_get(1,:).*max_chunk_size);
    im = im(imr(1,1):imr(2,1), imr(1,2):imr(2,2), imr(1,3):imr(2,3));
    
    im = upsample_im_mode(im, UPSMPL);
    
    
    fclose(fid);
    
end



function chunk_im = get_omni_chunk(fid, chunk_num, chunk_size, vol_size)

    bytes_per_cube = prod(chunk_size);    
    bytes_per_col = bytes_per_cube * vol_size(1)/chunk_size(1);
    bytes_per_plane = bytes_per_col * vol_size(2)/chunk_size(2);
    
    
    %am I in a squished cube-zone?
    if chunk_num(1)+1 > floor(vol_size(1)/chunk_size(1))
        chunk_size(1) = mod(vol_size(1), chunk_size(1));
    end
    if chunk_num(2)+1 > floor(vol_size(2)/chunk_size(2))
        bytes_per_cube = bytes_per_cube / chunk_size(2) * mod(vol_size(2), chunk_size(2));
        chunk_size(2) = mod(vol_size(2), chunk_size(2));
    end
    if chunk_num(3)+1 > floor(vol_size(3)/chunk_size(3))
        bytes_per_col = bytes_per_col / chunk_size(3) * mod(vol_size(3), chunk_size(3));
        bytes_per_cube = bytes_per_cube / chunk_size(3) * mod(vol_size(3), chunk_size(3));
        chunk_size(3) = mod(vol_size(3), chunk_size(3));
    end
    

    byte_pos = 4*(bytes_per_plane*(chunk_num(3)) + ...
        bytes_per_col * (chunk_num(2)) + ...
        bytes_per_cube * (chunk_num(1)));
    
    fseek(fid, byte_pos, 'bof');
    chunk_im = fread(fid, prod(chunk_size), 'uint32');
    chunk_im = reshape(chunk_im, chunk_size);
    
end
    
    
    