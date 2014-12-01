function supervoxels = make_dataset(coords, moment_depth)

   im = get_im_chunk(coords);
%    aff = get_affinity_chunk(coords);
%    lbl = get_label_chunk(coords);

   im_max = max(im(:));
   imnum2objnum = zeros(im_max,1);
   obj_max = 0;
   
   offset = (size(im)-1)/2;
   
   imSz = size(im);
   supervoxels = [];
   
   moment_factors = cell(moment_depth,1);
   for k = 1:moment_depth
       dummy = cell(1,k);
       [dummy{:}] = ind2sub(3*ones(1,k), (1:3^k)');       
       for l = 1:k
           moment_factors{k}(:,l) = dummy{l};
       end
   end
   
   %point
   for x = 1:imSz(1)
       for y = 1:imSz(2)
           for z = 1:imSz(3)
               
               if im(x,y,z) ~= 0
                   crd = [x y z] - offset;
                   
                   objnum = imnum2objnum(im(x,y,z));
                   if objnum == 0
                       obj_max = obj_max+1;
                       objnum = obj_max;
                       imnum2objnum(im(x,y,z)) = objnum;
                       supervoxels{objnum}.original_ID = im(x,y,z);
                       supervoxels{objnum}.size = 0;
                       
                       for k = 1:moment_depth
                            supervoxels{objnum}.moment{k} = zeros([3*ones(1,k) 1]);
                       end
                   end
                   
                   supervoxels{objnum}.size = supervoxels{objnum}.size+1;
                   
                   for k = 1:moment_depth
                       for l = 1:size(moment_factors{k},1)
                           supervoxels{objnum}.moment{k}(l) = prod(crd(moment_factors{k}(l,:)));
                       end
                   end
                       
                       
               end
           end
       end
   end
               
               
                       
   
   
   
   
   