function find_moment_translation_function()
    %fxn will take vector [x y z] to a matrix M, and v*M

    %so it's t -> tv, tv -> M by a length(tv) x numel(M) matrix?
    
    
    C = lash_constants;
    
    coeffs = [];
    for k = 1:C.moment_depth_generation
        kcoeffs = [];
        [kcoeffs(:,1), kcoeffs(:,2), kcoeffs(:,3)] = ind2sub((1+k)*ones(1,3), 1:(k+1)^3);
        kcoeffs = kcoeffs-1;
        kcoeffs = kcoeffs(sum(kcoeffs,2)==k,:);
        coeffs = [coeffs; kcoeffs];        
    end
    coeffs = [coeffs; 0 0 0];
    
    moment_length = size(coeffs,1);
    
    
    num_samples = 20;
    
    M = zeros(moment_length, moment_length, 4);
    for n = 1:4;
        
        invec = zeros(moment_length, moment_length^2);
        outvec = zeros(moment_length, moment_length^2);
        t = [1; 1; 1];
        if n <=3
            t(n) = 2;
        end
        for k = 1:moment_length^2
            for l = 1:num_samples
                r = randn(3,1);
                invec(:,k) = invec(:,k) + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
                r = r - t;
                outvec(:,k) = outvec(:,k) + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
            end
        end
        invec = invec/num_samples;
        outvec = outvec/num_samples;
        
        %M*iv = ov
        M(:,:,n) = round(outvec / invec);
    end
    for n = 1:3;
        M(:,:,n) = log(M(:,:,n)./M(:,:,4)) / log(2);        
    end   
    
    M(isnan(M)) = 0;
    
    disp(unique(M(:)));
    
    %test if it works!
       

    t = randn(3,1);
%     t = [1; 1; 1];
    
    invec = zeros(moment_length, 1);
    outvec = zeros(moment_length, 1);
    
    for l = 1:num_samples
        r = randn(3,1);
        invec = invec + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
        r = r - t;
        outvec = outvec + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
    end
    
    invec = invec/num_samples;
    outvec = outvec/num_samples;
    
    est_outvec = (M(:,:,4) .* t(1).^M(:,:,1) .* t(2).^M(:,:,2) .* t(3).^M(:,:,3)) * invec;
    
    new_line = 10;
    
    fid = fopen([C.translation_fxn_name '.m'], 'w');
    fwrite(fid, ['function v = ' C.translation_fxn_name '(v, t)' new_line 'v = [ ...' new_line]);
    for n = 1:moment_length-1;
        is_first_in_line = true;
        for k = 1:size(M, 2)
            if any(M(n,k,:))
                if ~is_first_in_line
                    if M(n,k,4) < 0
                        fwrite(fid, ' - ');
                    else
                        fwrite(fid, ' + ');
                    end
                else
                    if M(n,k,4) < 0
                        fwrite(fid, '-');
                    end
                    is_first_in_line = false;
                end

                if abs(M(n,k,4)) ~= 1
                    fwrite(fid, num2str(abs(M(n,k,4))));
                    needs_asterisk = true;
                else
                    needs_asterisk = false;
                end
                
                for l = 1:3
                    if M(n,k,l) ~= 0
                        if needs_asterisk
                            fwrite(fid, '*');
                        else
                            needs_asterisk = true;
                        end
                        if M(n,k,l) ~= 1
                            fwrite(fid, ['t(' num2str(l) ')^' num2str(M(n,k,l))]);
                        else
                            fwrite(fid, ['t(' num2str(l) ')']);
                        end
                    end
                end
                if k~=moment_length
                    if needs_asterisk
                        fwrite(fid, '*');
                    end
                    fwrite(fid, ['v(' num2str(k) ')']);
                end
            end            
        end
        if n < moment_length-1
            fwrite(fid, ['; ...' new_line]);
        else
            fwrite(fid, ['];' new_line 'end']);
        end

    end
                
                
    fclose(fid);
    save('../M.mat', 'M');
    
end
        
    
    
    