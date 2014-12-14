function v = rotate_vector(v, rules)  

    %determine thetas internally, later.
    submat = [v(4) v(5) v(6); v(5) v(3) v(8); v(6) v(8) v(9)];
    [eigvecs, eigvals] = svd(submat);
    for k = 1:3; 
        eigvecs(:,k) = eigvecs(:,k) * eigvals(k,k); 
    end
    Q = submat\eigvecs;
    %get thetas from Q...
    
    thetas = zeros(3,1);
    thetas(2) = asin(Q(1,3)); %val may be pi-val, cos(t(1)) will be +/-
    thetas(1) = acos(Q(1,1)/cos(thetas(2))); %if t2 is right, +/-.
    thetas(3) = acos(Q(3,3)/cos(thetas(2))); %if t2 is right, +/-.    
    
    if abs(-Q(2,3)/cos(thetas(2))- sin(thetas(3))) > .00001
        %assume thetas2 is correct
        thetas(3) = -thetas(3);        
    end
    if abs(-Q(1,2)/cos(thetas(2)) - sin(thetas(1))) > .00001
        thetas(1) = -thetas(1); 
    end
    
    
    
    
    for n = 1:3;
        M = zeros(length(v));
        for k = 1:size(rules{n}, 4);
            M = M + rules{n}(:,:,1,k) .* ...
                (sin(thetas(n)).^rules{n}(:,:,2,k)) .* ...
                (cos(thetas(n)).^rules{n}(:,:,3,k));
        end
        v = M*v;
    end
    
end
                