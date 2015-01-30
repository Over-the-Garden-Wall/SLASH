function SLASH_training(varargin)
    
    C = lash_constants;
    

%     handle params
    ip = inputParser;
%     ip.addOptional('axis_handle',gca, @(x) ishandle(x));
    ip.addParamValue('num_samples', 100, @(x) isnumeric(x));
    ip.addParamValue('halt_threshold', .5, @(x) isnumeric(x));
    ip.addParamValue('learn_from_seen', true, @(x) islogical(x));
    ip.addParamValue('learning_rate', .01, @(x) isnumeric(x));
    ip.addParamValue('max_attempts', Inf, @(x) isnumeric(x));    
    ip.addParamValue('test_fraction', .25, @(x) isnumeric(x));
    ip.addParamValue('moment_depth', 2, @(x) isnumeric(x) && x<=C.moment_depth_generation);
    ip.addParamValue('save_frequency', 10, @(x) isnumeric(x));
    ip.addParamValue('lognormalize', true, @(x) islogical(x));
    ip.addParamValue('network_size', [40 40 1], @(x) isnumeric(x));
    ip.addParamValue('net', [], @(x) true);    
    ip.addParamValue('max_training_iterations', 1000, @(x) isnumeric(x));    
    
       
    ip.parse(varargin{:});
    s = ip.Results;    
    
    %initialize everything
    moment_coeffs = coefficient_powers(3, s.moment_depth);
    moment_length = size(moment_coeffs,1);
    rotation_rules = find_moment_rotation_matrices(s.moment_depth);
    translation_rules = find_moment_translation_matrices(s.moment_depth);
    num_features = 4 + moment_length; 
    
    
    if s.lognormalize
        normal_f = @(x) sign(x).*log(1+abs(x));
    else
        normal_f = @(x) x;
    end
    
    
    %get training data
    dirs = dir(C.training_dir);
    is_valid_dir = false(length(dirs),1);
    training_fns = cell(length(dirs),1);
    
    for n = 1:length(dirs)
        if length(dirs(n).name) > 4 && strcmp(dirs(n).name(1:4), 'cube');
            training_fns{n} = dirs(n).name;
            is_valid_dir(n) = true;
        end
    end
    training_fns = training_fns(is_valid_dir);
    
    num_training_files = length(training_fns);    
    
    %set aside testing set
    is_test = false(num_training_files,1);
    randlist = randperm(num_training_files);
    is_test(randlist(1:floor(s.test_fraction*num_training_files))) = true;
    
    
    %initialize network
    if isempty(s.net)
        nn = create_neural_network([num_features s.network_size]);
    else
        load(s.net);
    end
    
    
    %initialize recording
    sample_results = zeros(s.num_samples, 5); %[is_test, num_attempts, max_correct, num_merges, did_quit];
    
    
    
    for n = 1:s.num_samples
        tic
        
        %prep sample
        file_pick = ceil(rand*num_training_files);
        is_test_file = is_test(file_pick);
        sample_results(n,1) = is_test_file;
        
        load([C.training_dir training_fns{file_pick}]);
        
        disp(['beginning: ' training_fns{file_pick}])
        
        segments.moments = segments.moments(:,1:moment_length);
        initial_segments = segments;
        initial_edge_data = edge_data;
        
        
        in_segs = find(segments.is_in);
        seed_pick = in_segs(ceil(rand*length(in_segs)));
        
        segments.moments = segments.moments(:,1:moment_length);
        
        %work out neighbors, I should do this at generation, probably
        neighbor_mat = zeros(length(segments.size));
        for k = 1:length(edge_data.total);
            neighbor_mat(edge_data.members(k,1), edge_data.members(k,2)) = k;            
        end
        neighbor_mat = neighbor_mat + neighbor_mat';
        neighbor_mat_copy = neighbor_mat;
        
        %find ground truth
        truth_group = seed_pick;
        neighbor_mat_copy(truth_group, :) = false;
        while 1
            neighbors = false(size(neighbor_mat,1),1);
            for k = 1:length(truth_group);
                neighbors = neighbors | (neighbor_mat_copy(:, truth_group(k)) > 0);
            end
            
            neighbor_mat_copy(neighbors,:) = false;
            in_neighbors = segments.is_in & neighbors;
            
            neighbor_list = find(in_neighbors);
            if isempty(neighbor_list)
                break
            end
            truth_group = [truth_group; neighbor_list];
            
            
        end
        sample_results(n,3) = length(truth_group);
        
        attempt_counter = 0;
        escape_flag = true;
        while escape_flag
            %sample reiteration
            
            attempt_counter = attempt_counter+1;
            
            seed_group = seed_pick;
            if is_test_file
                escape_flag = false;
            end
            neighbor_mat_copy = neighbor_mat;
            segments = initial_segments;
            edge_data = initial_edge_data;

            
            all_inputs = zeros(C.max_net_inputs, num_features);
            all_labels = zeros(C.max_net_inputs, 1);
            input_counter = 0;
            merge_counter = 0;
            
            while 1
                %SLASH iteration
                
                neighbors = neighbor_mat_copy(:, seed_group(1));
                neighbor_list = find(neighbors);

                net_input = zeros(length(neighbor_list), num_features);
                net_labels = zeros(length(neighbor_list), 1);
                
                
                for k = 1:length(neighbor_list)
                    nk = neighbor_mat_copy(seed_pick, neighbor_list(k));
                    
                    ms = edge_data.members(nk,:);
                    moment_vec = (segments.moments(ms(1), :) + ...
                        segments.moments(ms(2), :)) / ...
                        (segments.size(ms(1))+segments.size(ms(2)));
                    moment_vec = translate_vector(moment_vec', edge_data.com(nk,:), translation_rules)';
                    moment_vec = rotate_vector(moment_vec', rotation_rules)';
                    
                    
                    net_input(k,:) = [edge_data.total(nk)/edge_data.count(nk), edge_data.max(nk), ...
                        edge_data.min(nk), edge_data.count(nk), ...
                        moment_vec];
                    net_labels(k) = edge_data.is_correct(nk);
                end
                    
                net_input(:,1:3) = net_input(:,1:3)-.5;
                net_input(:,4:end) = normal_f(net_input(:,4:end));
                
                all_inputs(input_counter + (1:length(net_labels)),:) = net_input;
                all_labels(input_counter + (1:length(net_labels))) = net_labels;
                input_counter = input_counter + length(net_labels);
                
                
                net_output = run_nn(nn, net_input);                                                
                [best_val, best_ind] = max(net_output);                
                to_merge = neighbor_list(best_ind);
                
                if best_val < s.halt_threshold
                    sample_results(n,5) = 1;
                    break
                    
                elseif ~segments.is_in(to_merge);
                    %wrong
                    sample_results(n,5) = 0;
                    inner_escape_flag = false;
                    
                else
                    %right, merge segments
                    merge_counter = merge_counter + 1;
                
                    new_neighbors = neighbor_mat_copy(:, to_merge);
                    
                    shared_edges = new_neighbors>0 & neighbors>0;
                    shared_edges_list = find(shared_edges);
                    
                    for k = 1:length(shared_edges_list);
                        edge_data = merge_edge_data(edge_data, neighbors(shared_edges_list(k)), new_neighbors(shared_edges_list(k))); %TODO
                    end
                    
                    segments = merge_segments(segments, seed_pick, to_merge); %TODO
                    seed_group = [seed_group; to_merge];
                    
                    neighbor_mat_copy(:, to_merge) = 0;
                    neighbor_mat_copy(to_merge, shared_edges) = 0;
                    neighbor_mat_copy(seed_pick, :) = neighbor_mat_copy(seed_pick, :) + neighbor_mat_copy(to_merge, :);
                end
                    
                
            end
            
            toc;
            disp('iteration over, training network');
            tic
                    
            
            
            %train network
            for t = 1:s.max_training_iterations
                [nn E] = train_nn(nn, all_inputs(1:input_counter,:), all_labels(1:input_counter)*2-1);
                if all(E < (1-s.halt_threshold)^2)
                    break                    
                end
            end
            
            toc
            if merge_counter == length(truth_group)-1 || attempt_counter > s.max_attempts
                break
            end
            
        end
        
        sample_results(n,4) = merge_counter;
        sample_results(n,2) = attempt_counter;
    end
    
end