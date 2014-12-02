function im = get_im_chunk(imdir, coords)

    OVERLAP = [32 32 32];
    CHUNKSIZE = [128 128 128];
    CUBESIZE = [256 256 256];
    OFFSET = [466 498 679] - CUBESIZE + OVERLAP;
    
    
    cubes_to_get = [floor((coords(1,:) - OFFSET)./(CUBESIZE-OVERLAP)); ...
        floor((coords(2,:) - OFFSET)./(CUBESIZE-OVERLAP))];
    
    im = zeros((cubes_to_get(2,:) - cubes_to_get(1,:)).*(CUBESIZE-OVERLAP) + CUBESIZE);
    
    for x = cubes_to_get(1,1):cubes_to_get(2,1)
        for y = cubes_to_get(1,2):cubes_to_get(2,2)
            for z = cubes_to_get(1,3):cubes_to_get(2,3)
                s = ([x y z] - cubes_to_get(1,:)) .* (CUBESIZE-OVERLAP);
                im(s(1) + (1:CUBESIZE(1)), s(2) + (1:CUBESIZE(2)), s(3) + (1:CUBESIZE(3))) = ...
                    get_cube_im([x y z], imdir, CHUNKSIZE, CUBESIZE);
            end
        end
    end
                
    imr = coords - ones(2,1)*(OFFSET + cubes_to_get(1,:).*(CUBESIZE-OVERLAP));
    im = im(imr(1,1):imr(2,1), imr(1,2):imr(2,2), imr(1,3):imr(2,3));
    
end

function im = get_cube_im(cube_loc, imdir, chunkSz, cubeSz)
    xstr = format_num(cube_loc(1),2);
    ystr = format_num(cube_loc(2),2);
    zstr = format_num(cube_loc(3),2);
    fn = [imdir '/x' xstr '/y' ystr '/im_x' xstr 'y' ystr 'z' zstr '.raw'];
    
    fid = fopen(fn, 'r');
    im = fread(fid, 'float');
    chunks_per_cube = cubeSz./chunkSz;
    
    im = reshape(im, [chunkSz chunks_per_cube]);
    im = permute(im, [1 4 2 5 3 6]);
    im = reshape(im, cubeSz);
end