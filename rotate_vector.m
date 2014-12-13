function v = rotate_vector(v, thetas, rules)  

    %determine thetas internally, later.
    
    for n = 1:3;
        M = zeros(length(v));
        for k = 1:size(rules, 4);
            M = M + rules{n}(:,:,1,k) .* ...
                (sin(thetas(n)).^rules{n}(:,:,2,k)) .* ...
                (cos(thetas(n)).^rules{n}(:,:,3,k));
        end
        v = M*v;
    end
    
end
                