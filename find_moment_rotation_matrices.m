function M = find_moment_rotation_matrices()
    %assumed that M is centered first.
    
    %going to have to find a n^2 x n? matrix N such that:
    % reshape(N*thetavec, [n n]) * v = rv
    % thetavec = [sin(a); cos(a); sin(b); cos(b); sin(c); cos(c); 1];
    
    C = lash_constants;
    
        
%         Q = [1 0 0; 0 cos(t(1)) -sin(t(1)); 0 sin(t(1)) cos(t(1))] * ...
%             [cos(t(3)) -sin(t(3)) 0; sin(t(3)) cos(t(3)) 0; 0 0 1] * ...
%             [cos(t(2)) 0 sin(t(2)); 0 1 0; -sin(t(2)) 0 cos(t(2))];

    
    %find 2d rotation about z
    coeffs = coefficient_powers(2, C.moment_depth_generation);
    coeff_order = sum(coeffs,2);
    
    num_samples = 20;

    tic
    
    
    M = find_rotation_by_brute_force(rand*2, coeffs, num_samples);   
    is_nonzero = abs(M)>=10^-6;
    
    M = find_rotation_by_brute_force(pi/4, coeffs, num_samples);   
    
    
    

    toc

    %M*q = Ms
%     M = Ms / q;
        
end
        

function M = find_rotation_by_brute_force(theta, coeffs, num_samples)
    
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
    
    