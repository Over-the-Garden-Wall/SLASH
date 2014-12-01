function copy_segmentation(omni_file_dir, out_dir, write_chunks)

    
    %get volume size
    fid = fopen([omni_file_dir '/projectMetadata.yaml'],'r');
%     fid = fopen(['./projectMetadata.yaml'],'r');
    
    metadata = fread(fid,'char')';
    
    data_dim_spot = strfind(metadata, 'dataDimensions');
    metadata = char(metadata(data_dim_spot(1):data_dim_spot(1)+100));
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
    
    num_chunks = ceil(imSz./max_chunk_size);
    c = zeros(1,3);
    
    fid = fopen([omni_file_dir './segmentations/segmentation1/0/volume.uint32_t.raw']);
%     fid = fopen([omni_file_dir './volume.uint32_t.raw']);
        
    disp(num_chunks);
    disp(max_chunk_size);
    
    for n = 1:prod(num_chunks)
        tic
        [c(1), c(2), c(3)] = ind2sub(num_chunks, n);              
        
        chunkSz = max_chunk_size;
        for k = 1:3
            if c(k) == num_chunks(k)
                chunkSz(k) = mod(imSz(k),max_chunk_size(k));
                if chunkSz(k) == 0;
                    chunkSz(k) = max_chunk_size(k);
                end
            end
        end
        
        chunk_data = fread(fid,prod(chunkSz),'uint32');
%             disp(c); disp(write_chunks);
        if all(c >= write_chunks(1,:)) && all(c <= write_chunks(2,:))
            xdir = [out_dir '/x' format_num(c(1),2)];
            if ~exist(xdir, 'dir')
                mkdir(xdir);
            end
            ydir = [xdir '/y' format_num(c(2),2)];
            if ~exist(ydir, 'dir')
                mkdir(ydir);
            end
            out_fn = [ydir '/lbl_x' format_num(c(1),2) 'y' format_num(c(2),2) 'z' format_num(c(3),2) '.raw'];
            
            
            wfid = fopen(out_fn, 'w');
            fwrite(wfid, chunk_data(:), 'uint32');
            fclose(wfid);
            
        end

        
        disp(['writing block ' num2str(n) ' of ' num2str(prod(num_chunks))])
        toc
    end
    
    
end

function outstr = format_num(num, digits)

    outstr = num2str(num);
    outstr = ['0' * ones(1,digits-length(outstr)), outstr];
end