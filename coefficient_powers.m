function coeffs = coefficient_powers(num_variables, coeff_depth)


    coeffs = [];
    for k = 1:coeff_depth
        cell_coeffs = cell(1,num_variables);
        [cell_coeffs{:}] = ind2sub((1+k)*ones(1,num_variables), (1:(k+1)^num_variables)');
        kcoeffs = [cell_coeffs{:}];
        kcoeffs = kcoeffs-1;
        kcoeffs = kcoeffs(sum(kcoeffs,2)==k,:);
        coeffs = [coeffs; kcoeffs];        
    end
    
end