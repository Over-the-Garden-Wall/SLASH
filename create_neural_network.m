function nn = create_neural_network(net_size, weight_initial_distribution, bias_initial_distribution)

    if ~exist('weight_initial_distribution', 'var') || isempty(weight_initial_distribution)
        weight_initial_distribution = .01;
    end
    if length(weight_initial_distribution) == 1
        weight_initial_distribution = weight_initial_distribution * ones(length(net_size)-1,1);
    end
    
    if ~exist('bias_initial_distribution', 'var') || isempty(bias_initial_distribution)
        bias_initial_distribution = .01;
    end
    if length(bias_initial_distribution) == 1
        bias_initial_distribution = bias_initial_distribution * ones(length(net_size)-1,1);
    end
    
    
    for n = 1:length(net_size)-1
        nn.W{n} = ones(net_size(n), net_size(n+1)) * weight_initial_distribution(n);
    end
    for n = 1:length(net_size)-1
        nn.B{n} = ones(1, net_size(n+1)) * bias_initial_distribution(n);
    end
        
end