function [v, vt, vr] = generate_sample_vector(num_vecs, samples_vec, translat, rotation_thetas, dpth)

    if ~exist('dpth','var') || isempty(dpth)
        C = lash_constants;
        dpth = C.moment_generation_depth;
    end

    cfs = coefficient_powers(3,dpth);
    
    
    v = zeros(size(cfs,1), num_vecs);
    vt = zeros(size(v));
    vr = zeros(size(v));
    t = rotation_thetas;
    Q = [1 0 0; 0 cos(t(3)) -sin(t(3)); 0 sin(t(3)) cos(t(3))] * ...
        [cos(t(2)) 0 sin(t(2)); 0 1 0; -sin(t(2)) 0 cos(t(2))] * ...
        [cos(t(1)) -sin(t(1)) 0; sin(t(1)) cos(t(1)) 0; 0 0 1];
        
    for n = 1:num_vecs;
        for k = 1:samples_vec
            r = randn(3,1);
            v(:,n) = v(:,n) + (r(1).^cfs(:,1)) .* (r(2).^cfs(:,2)) .* (r(3).^cfs(:,3));
            r = r - translat;
            vt(:,n) = vt(:,n) + (r(1).^cfs(:,1)) .* (r(2).^cfs(:,2)) .* (r(3).^cfs(:,3));
            r = Q*r;
            vr(:,n) = vr(:,n) + (r(1).^cfs(:,1)) .* (r(2).^cfs(:,2)) .* (r(3).^cfs(:,3));
        end
    end
end
            
            
    
