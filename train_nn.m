function [nn, E] = train_nn(nn, data_block, labels)

    [out_block, F] = run_nn(nn, data_block);
    batch_size = size(data_block,1);
    
    E = (out_block - labels).^2;
    dEdB = ones(batch_size, 1) * (out_block - labels);
    
    lambda = ones(length(nn.W),1) * .01 / batch_size;
    lambda(end) = lambda(end)*.1;
    
    for n = length(nn.W):-1:1
        dEdB = dEdB .* (1-F{n+1}).^2;
        
        dEdW = F{n}' * dEdB;

        nn.B{n} = nn.B{n} - sum(dEdB)*lambda(n);
        
        dEdB = dEdB * nn.W{n}';
        
        nn.W{n} = nn.W{n} - dEdW*lambda(n);
    end
    
end
        
        
    