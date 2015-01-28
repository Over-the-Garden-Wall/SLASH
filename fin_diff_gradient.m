function dEdB = fin_diff_gradient(nn, data_block, labels)

    delta = .001;

    [out_block, F] = run_nn(nn, data_block);
    
    E = (out_block - labels).^2;
    E = sum(E(:),1);
    
    dEdB = cell(length(nn.W),1);
    for l = 1:length(nn.W)
        dEdB{l} = zeros(1, length(nn.B{l}));
        for f = 1:length(nn.B{l});
            nn.B{l}(f) = nn.B{l}(f) + delta;
            [out_block, F] = run_nn(nn, data_block);
            new_E = (out_block - labels).^2;
            dEdB{l}(f) = (sum(new_E(:)) - E) / delta;
            nn.B{l}(f) = nn.B{l}(f) - delta;
        end
    end
            
    
end
    