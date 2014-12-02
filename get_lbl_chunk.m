function im = get_lbl_chunk(lbldir, coords)

    OVERLAP = [16 16 16];
    CHUNKSIZE = [128 128 128];
    CUBESIZE = [128 128 128];
    UPSMPL = [2 2 2];
    OFFSET = [466 498 680]./UPSMPL - CUBESIZE + OVERLAP;
    
    coords = floor(coords ./ ones(2,1)*UPSMPL);
    
    cubes_to_get = [floor((coords(1,:) - OFFSET)./(CUBESIZE-OVERLAP)); ...
        floor((coords(2,:) - OFFSET)./(CUBESIZE-OVERLAP))];
    
    im = zeros((cubes_to_get(2,:) - cubes_to_get(1,:)).*(CUBESIZE-OVERLAP) + CUBESIZE, 'uint32');
    
    for x = cubes_to_get(1,1):cubes_to_get(2,1)
        for y = cubes_to_get(1,2):cubes_to_get(2,2)
            for z = cubes_to_get(1,3):cubes_to_get(2,3)
                s = ([x y z] - cubes_to_get(1,:)) .* (CUBESIZE-OVERLAP);
                im(s(1) + (1:CUBESIZE(1)), s(2) + (1:CUBESIZE(2)), s(3) + (1:CUBESIZE(3))) = ...
                    get_cube_im([x y z], lbldir, CHUNKSIZE, CUBESIZE);
            end
        end
    end
                
    imr = coords - ones(2,1)*(OFFSET + cubes_to_get(1,:).*(CUBESIZE-OVERLAP));
    im = im(imr(1,1):imr(2,1), imr(1,2):imr(2,2), imr(1,3):imr(2,3));
    
    im = upsample_im_mode(im, UPSMPL);
end

function im = get_cube_im(cube_loc, imdir, chunkSz, cubeSz)
    xstr = format_num(cube_loc(1),2);
    ystr = format_num(cube_loc(2),2);
    zstr = format_num(cube_loc(3),2);
    fn = [imdir '/x' xstr '/y' ystr '/im_x' xstr 'y' ystr 'z' zstr '.raw'];
    
    fid = fopen(fn, 'r');
    im = fread(fid, 'uint32');
    im = uint32(im);
    chunks_per_cube = cubeSz./chunkSz;
    
    im = reshape(im, [chunkSz chunks_per_cube]);
    im = permute(im, [1 4 2 5 3 6]);
    im = reshape(im, cubeSz);
end

function new_im = upsample_im_mode(im, upsampling)
    new_im = zeros([size(im) upsampling], 'uint32');
    for k = 1:prod(upsampling);
        new_im(:,:,:,k) = im;
    end
    
    new_im = permute(new_im, [1 4 2 5 3 6]);
    new_im = reshape(new_im, size(im).*upsampling);
end
    
    