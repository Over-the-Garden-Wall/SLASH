function M = find_moment_translation_function()

    %so it's t -> tv, tv -> M by a length(tv) x numel(M) matrix?
    
    
    C = lash_constants;
    
    coeffs = coefficient_powers(3, C.moment_depth_generation);
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
%     
    M(isnan(M)) = 0;
    M(end,:,:) = [];
%     
%     disp(unique(M(:)));
%     
%     %test if it works!
%        
% 
%     t = randn(3,1);
% %     t = [1; 1; 1];
%     
%     invec = zeros(moment_length, 1);
%     outvec = zeros(moment_length, 1);
%     
%     for l = 1:num_samples
%         r = randn(3,1);
%         invec = invec + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
%         r = r - t;
%         outvec = outvec + r(1).^coeffs(:,1) .* r(2).^coeffs(:,2) .* r(3).^coeffs(:,3);
%     end
%     
%     invec = invec/num_samples;
%     outvec = outvec/num_samples;
%     
%     est_outvec = (M(:,:,4) .* t(1).^M(:,:,1) .* t(2).^M(:,:,2) .* t(3).^M(:,:,3)) * invec;
    

    
    
end
        
    
    
    