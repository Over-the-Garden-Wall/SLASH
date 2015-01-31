function [out_block, F] = run_nn(nn, data_block)

    F = cell(length(nn.W)+1,1);
    F{1} = data_block;
    
    for n = 1:length(nn.W)
        pF = F{n} * nn.W{n} + ones(size(data_block,1),1)*nn.B{n};
        pF = tanh(pF);
        F{n+1} = pF;
%         F{n+1} = tanh( F{n} * nn.W{n} +
%         ones(size(data_block,1),1)*nn.B{n} );
    end
    
    out_block = F{end};
    
end

