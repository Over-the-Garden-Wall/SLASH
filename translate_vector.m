function v = translate_vector(v, t, rules)

    trans_mat = (rules(:,:,4) .* t(1).^rules(:,:,1) .* t(2).^rules(:,:,2) .* t(3).^rules(:,:,3));
    
    v = trans_mat * [v; ones(1,size(v,2))];
    
end