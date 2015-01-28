function Ms = find_moment_rotation_matrices(dpth)
    %assumed that M is centered first.
    
    %going to have to find a n^2 x n? matrix N such that:
    % reshape(N*thetavec, [n n]) * v = rv
    % thetavec = [sin(a); cos(a); sin(b); cos(b); sin(c); cos(c); 1];
    
    C = lash_constants;
    
        
%         Q = [1 0 0; 0 cos(t(1)) -sin(t(1)); 0 sin(t(1)) cos(t(1))] * ...
%             [cos(t(3)) -sin(t(3)) 0; sin(t(3)) cos(t(3)) 0; 0 0 1] * ...
%             [cos(t(2)) 0 sin(t(2)); 0 1 0; -sin(t(2)) 0 cos(t(2))];

    
    %find 2d rotation about z
    coeffs2d = coefficient_powers(2, dpth);
    coeff_order = sum(coeffs2d,2);
    
    order_mat = zeros(length(coeff_order));
    
    for n = 1:dpth
        order_mat = order_mat + ((coeff_order==n)*n)*(coeff_order==n)';
    end
    
    num_samples = 2;

    temp_mats = cell(dpth,1);
    
    for n = 1:dpth
        tic
        num_M_of_order = sum(order_mat(:)==n);
        
        rs = ones(n+1, (n+1)*num_M_of_order);
        Ms = ones(num_M_of_order, (n+1)*num_M_of_order);
        
        my_sincos_powers = zeros(n+1,2);
        for l = 0:n
            my_sincos_powers(l+1,:) = [l, n-1];
        end
        
        for k = 1:(n+1)*num_M_of_order
            r = rand*pi;
            rs(:, k) = (sin(r).^my_sincos_powers(:,1)).*(cos(r).^my_sincos_powers(:,2));
            for l = 0:n
                rs(l+1, k) = sin(r)^l*cos(r)^(n-l);
            end
            M = find_2drotation_by_brute_force(r, coeffs2d, num_samples);  
            Ms(:,k) = M(order_mat(:)==n);
        end
        %X * rs = M
        
        temp_mats{n} = round(Ms / rs);
        toc;
    end
    
    
    num_adds = 0;
    for n = 1:dpth
        num_adds = max([num_adds; sum(temp_mats{n}~=0,2)]);
    end
    
    rotM2d = zeros([num_adds, 3, size(M)]);
    
    for n = 1:dpth
        %split into additions
        inds_in_M = find(order_mat==n);
        for k = 1:size(temp_mats{n},1)
            for l = 1:num_adds
                fI = find(temp_mats{n}(k,:),1,'first');
                if isempty(fI)
                    break
                end
                fV = temp_mats{n}(k,fI);
                temp_mats{n}(k,fI) = 0;
                rotM2d(l, 1, inds_in_M(k)) = fV;
                rotM2d(l, 2, inds_in_M(k)) = fI-1;
                rotM2d(l, 3, inds_in_M(k)) = n+1-fI;
                
            end
        end
    end
%     rotM2d = permute(rotM2d, [3 4 2 1]);
    
    
    
    %expand rotM2d to 3 3d matrices.
        
    coeffs = coefficient_powers(3, dpth);
    
    
    sample_theta = .6;
    
    M2d = find_2drotation_by_brute_force(sample_theta, coeffs2d, num_samples);
    error_factor = 100000;
    M2d = round(M2d*error_factor);
    
    correspondance = cell(3,1);
    for v = 1:3
        t = zeros(1,3);
        t(v) = sample_theta;
        M = find_3drotation_by_brute_force(t, coeffs, num_samples);    
        M = round(M*error_factor);
        correspondance{v} = zeros(size(M));
        for k = 1:numel(M)
            if M(k) ~= 0
                if M(k) == error_factor
                    correspondance{v}(k) = -1;
                else
                    n = find(M2d == M(k),1,'first');
%                     disp(n)
                    correspondance{v}(k) = n;
                end
            end
        end
    end
    
    
    %omg, endgame!
    Ms = cell(3,1);
    for n = 1:3
        Ms{n} = zeros([num_adds, 3, size(M)]);
        for k = 1:numel(M)
            if correspondance{n}(k) == -1;
                Ms{n}(1,:,k) = [1, 0, 0];
            elseif correspondance{n}(k) ~= 0;
                Ms{n}(:,:,k) = rotM2d(:,:,correspondance{n}(k));
            end
        end
        Ms{n} = permute(Ms{n}, [3 4 2 1]);
    end
    
    
    %test
%     M = zeros(length(v));
%     for k = 1:size(Ms{1}, 4);
%         M = M + Ms{n}(:,:,1,k) .* ...
%             (sin(thetas(n)).^Ms{n}(:,:,2,k)) .* ...
%             (cos(thetas(n)).^Ms{n}(:,:,3,k));
%     end
    
end
        

function M = find_2drotation_by_brute_force(theta, coeffs, num_samples)
    
    moment_length = size(coeffs,1);
    
    Q = [cos(theta), -sin(theta); sin(theta), cos(theta)];
        
    invec = zeros(moment_length, moment_length);
    outvec = zeros(moment_length, moment_length);

    
    for k = 1:moment_length
        for l = 1:num_samples
            r = randn(2,1);
            invec(:,k) = invec(:,k) + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2);
            r = Q*r;
            outvec(:,k) = outvec(:,k) + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2);
        end
    end
    
    invec = invec/num_samples;
    outvec = outvec/num_samples;
        
        %M*iv = ov
    M = outvec / invec;
end

function M = find_3drotation_by_brute_force(t, coeffs, num_samples)
    
    moment_length = size(coeffs,1);
    
    [invec, vt, outvec] = generate_sample_vector(moment_length, num_samples, [0; 0; 0], t, max(sum(coeffs,2)));

    
    invec = invec/num_samples;
    outvec = outvec/num_samples;
        
        %M*iv = ov
    M = outvec / invec;
end
    
    