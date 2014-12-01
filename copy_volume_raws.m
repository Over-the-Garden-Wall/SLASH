function copy_volume_raws(src_dir, dest_dir)

    xdir_names = dir(src_dir);
    
    for x = 1:length(xdir_names)
        if strcmp(xdir_names(x).name(1), 'x') && strcmp(xdir_names(x).name(2:3), '09') 
            mkdir([dest_dir '/'  xdir_names(x).name]);
            ydir_names = dir([src_dir '/'  xdir_names(x).name]);
            for y = 1:length(ydir_names)
                if strcmp(ydir_names(y).name(1), 'y')
                    mkdir([dest_dir '/' xdir_names(x).name '/' ydir_names(y).name]);
                    zdir_names = dir([src_dir '/' xdir_names(x).name '/' ydir_names(y).name]);
                    for z = 1:length(zdir_names)
                        if strcmp(zdir_names(z).name(1), 'x') && ~strcmp(zdir_names(z).name(2), 'x') && zdir_names(z).isdir
                            copyfile( ...
                                [src_dir '/' xdir_names(x).name '/' ydir_names(y).name '/' zdir_names(z).name '/channels/channel1/0/volume.float.raw'], ...
                                [dest_dir '/' xdir_names(x).name '/' ydir_names(y).name '/im_' zdir_names(z).name(1:9) '.raw']);
                            
                            copyfile( ...
                                [src_dir '/' xdir_names(x).name '/' ydir_names(y).name '/' zdir_names(z).name '/segmentations/segmentation1/0/volume.uint32_t.raw'], ...
                                [dest_dir '/' xdir_names(x).name '/' ydir_names(y).name '/seg_' zdir_names(z).name(1:9) '.raw']);
                            
                        end
                    end
                end
            end
        end
    end
                            
                            
                            
end                