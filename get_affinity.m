function im = get_affinity(coords)

    coords = coords - 18;
    coords(:,1) = coords(:,1)+128;
    
    cube_size = 128 * ones(1,3);
    
    
    
    chunks_to_get = [floor(coords(1,:)./cube_size); ...
        floor(coords(2,:)./cube_size)];
    
    im = zeros([(chunks_to_get(2,:) - chunks_to_get(1,:) + 1).*cube_size, 3]);
    
    for x = chunks_to_get(1,1):chunks_to_get(2,1)
        for y = chunks_to_get(1,2):chunks_to_get(2,2)
            for z = chunks_to_get(1,3):chunks_to_get(2,3)
                s = ([x y z] - chunks_to_get(1,:)) .* cube_size;                                
                im(s(1) + (1:cube_size(1)), s(2) + (1:cube_size(2)), s(3) + (1:cube_size(3)), :) = ...
                    get_aff_cube([x y z]);
            end
        end
    end
                
    imr = coords - ones(2,1)*(chunks_to_get(1,:).*cube_size);
    im = im(imr(1,1):imr(2,1), imr(1,2):imr(2,2), imr(1,3):imr(2,3), :);
    
    
end



function aff = get_aff_cube(cube_num)
    C = lash_constants;
    
    xstr = format_num(cube_num(1), 3);
    ystr = format_num(cube_num(2), 3);
    zstr = format_num(cube_num(3), 3);
    
    fn = [C.affinity_dir  '/' xstr '/' ystr '/' zstr '/aff' xstr '_' ystr '_' zstr '.raw']; 
    
    fid = fopen(fn,'r');
    aff = fread(fid, 'float');
    aff = reshape(aff, [128 128 128 3]);
    fclose(fid);
    
end
    
    
    