function copy_segmentation(omni_file_dir, out_dir, write_coords, write_size, overlap)

    
    %get volume size
    fid = fopen([omni_file_dir '/projectMetadata.yaml'],'r');
%     fid = fopen(['./projectMetadata.yaml'],'r');
    
    metadata = fread(fid,'char')';
    
    data_dim_spot = strfind(metadata, 'dataDimensions');
    metadata = char(metadata(data_dim_spot(1):data_dim_spot(1)+300));
    % dataDimensions: [123, 3456, 12222]
    
    spaces = find(isspace(metadata));
    imSz(1) = str2double(metadata(spaces(1)+2:spaces(2)-2));
    imSz(2) = str2double(metadata(spaces(2)+1:spaces(3)-2));
    imSz(3) = str2double(metadata(spaces(3)+1:spaces(4)-2));
    
    
%     data_dim_spot = strfind(metadata, 'dataResolution');
%     metadata = char(metadata(data_dim_spot(1):data_dim_spot(1)+100));
%     % dataDimensions: [123, 3456, 12222]
%     
%     spaces = find(isspace(metadata));
%     res(1) = str2double(metadata(spaces(1)+2:spaces(2)-2));
%     res(2) = str2double(metadata(spaces(2)+1:spaces(3)-2));
%     res(3) = str2double(metadata(spaces(3)+1:spaces(4)-2));
%     
%     imSz = imSz./res;
    
    chunk_size_spot = strfind(metadata, 'chunkDim');
    metadata = metadata(chunk_size_spot(1):end);
    spaces = find(isspace(metadata));
    chunkEdge = str2double(metadata(spaces(1)+1:spaces(2)-1));
    
    fclose(fid);
    
%
%
    
    max_chunk_size = chunkEdge*ones(1,3);
    
    if ~exist('overlap','var') || isempty(overlap)
        overlap = [0 0 0];
    end
    
    num_chunks = ceil(imSz./max_chunk_size);
    c = zeros(1,3);
    
    fid = fopen([omni_file_dir './segmentations/segmentation1/0/volume.uint32_t.raw']);
%     fid = fopen([omni_file_dir './volume.uint32_t.raw']);
        
%     disp(num_chunks);
%     disp(max_chunk_size);
    
    disp(imSz);
    
    num_chunks_to_write = ceil((overlap+1+(write_coords(2,:) - write_coords(1,:)))./(write_size-overlap));
%     
%     disp(write_coords)
%     disp(num_chunks_to_write);
    
    for n = 1:prod(num_chunks_to_write)
    
        tic
        
        [c(1), c(2), c(3)] = ind2sub(num_chunks_to_write, n);              
        chunk_coords = [((c-1).*(write_size-overlap)) + write_coords(1,:); ...
            min([((c-1).*(write_size-overlap)) + write_coords(1,:) + write_size - 1; imSz])];
                
        disp(chunk_coords);
        
        chunk_im = get_omni_coords(fid, chunk_coords, max_chunk_size, imSz);


        xdir = [out_dir '/x' num2str(chunk_coords(1,1))];
        if ~exist(xdir, 'dir')
            mkdir(xdir);
        end
        ydir = [xdir '/y' num2str(chunk_coords(1,2))];
        if ~exist(ydir, 'dir')
            mkdir(ydir);
        end
        out_fn = [ydir '/lbl_x' ...
            num2str(chunk_coords(1,1)) 'y' num2str(chunk_coords(1,2)) 'z' num2str(chunk_coords(1,3)) '.raw'];


        wfid = fopen(out_fn, 'w');
        fwrite(wfid, chunk_im(:), 'uint32');
        fclose(wfid);


        
        disp(['written block ' num2str(n) ' of ' num2str(prod(num_chunks_to_write))])
        toc
    end
    fclose(fid);
    
end

function outstr = format_num(num, digits)

    outstr = num2str(num);
    outstr = ['0' * ones(1,digits-length(outstr)), outstr];
end

function out_im = get_omni_coords(fid, chunk_coords, max_chunk_size, vol_size)
    chunks_to_read = [1+floor((chunk_coords(1,:)-1)./max_chunk_size); ...
        ceil((chunk_coords(2,:))./max_chunk_size)];
%     
%     disp(chunk_coords);
%     disp(max_chunk_size);
%     disp(chunks_to_read);
    
    
    offset = chunk_coords(1,:) - (chunks_to_read(1,:)-1).*max_chunk_size - 1;
    out_Sz = chunk_coords(2,:) - chunk_coords(1,:) + 1;
    out_im = zeros((chunks_to_read(2,:)-chunks_to_read(1,:)+1).*max_chunk_size);
    
    for x = chunks_to_read(1,1):chunks_to_read(2,1)
        for y = chunks_to_read(1,2):chunks_to_read(2,2)
            for z = chunks_to_read(1,3):chunks_to_read(2,3)
                chunk_im = get_omni_chunk(fid, ([x y z]-1).*max_chunk_size + 1, max_chunk_size, vol_size);
                out_im((x-chunks_to_read(1,1))*max_chunk_size(1) + (1:size(chunk_im,1)), ...
                    (y-chunks_to_read(1,2))*max_chunk_size(2) + (1:size(chunk_im,2)), ...
                    (z-chunks_to_read(1,3))*max_chunk_size(3) + (1:size(chunk_im,3))) = chunk_im;
            end
        end
    end
    
%     disp(out_Sz)
%     disp(offset)
    out_im = out_im(offset(1) + (1:out_Sz(1)), offset(2) + (1:out_Sz(2)), offset(3) + (1:out_Sz(3)));
    
%     disp(size(out_im));
end

function chunk_im = get_omni_chunk(fid, chunk_start, chunk_size, vol_size)

    chunk_num = (chunk_start-1)./chunk_size;    
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
    

    byte_pos = bytes_per_plane*(chunk_num(3)) + ...
        bytes_per_col * (chunk_num(2)) + ...
        bytes_per_cube * (chunk_num(1));
    
    fseek(fid, byte_pos, 'bof');
    chunk_im = fread(fid, prod(chunk_size), 'uint32');
    chunk_im = reshape(chunk_im, chunk_size);
    
end
    
    
    