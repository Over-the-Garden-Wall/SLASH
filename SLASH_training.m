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
    
       
    ip.parse(varargin{:});
    s = ip.Results;    
    
    %initialize everything
    moment_coeffs = coefficient_powers(3, s.moment_depth);
    moment_length = size(moment_coeffs,1);
    rotation_rules = find_moment_rotation_matrices(s.moment_depth);
    translation_rules = find_moment_translation_matrices(s.moment_depth);
    
    
    %get training data
    dirs = C.training_dir;
    is_valid_dir = false(length(dirs),1);
    training_fns = cell(length(dirs),1);
    
    for n = 1:length(dirs)
        if length(dirs(n).name) > 4 && strcmp(dirs(n).name(1:4), 'cube');
            training_fns{n} = dirs(n).name;
            is_valid_dir(n) = true;
        end
    end
    training_fns = sample_fns(is_valid_dir);
    
    num_training_files = length(training_fns);    
    
    %set aside testing set
    is_test = false(num_training_files,1);
    randlist = randperm(num_training_files);
    is_test(randlist(1:floor(s.test_fraction*num_training_files))) = true;
    
    
    %initialize recording
    
    
    for n = 1:s.num_samples
        %prep sample
        file_pick = ceil(rand*num_training_files);
        is_test_file = is_test(file_pick);
        load([C.training_dir training_fns{file_pick}]);
        
        in_segs = find(segments.is_in);
        seed_pick = in_segs(ceil(rand*length(in_segs)));
        
        segments.moments = segments.moments(:,1:moment_length);
        
        %work out neighbors, I should do this at generation, probably
        neighbor_mat = false(length(segments.size));
        for k = 1:length(edge_data.total);
            neighbor_mat(edge_data.members(k,1), edge_data.members(k,2)) = true;            
        end
        neighbor_mat = neighbor_mat | neighbor_mat';
        neighbor_mat_copy = neighbor_mat;
        
        %find ground truth
        truth_group = seed_pick;
        neighbor_mat_copy(truth_group, :) = false;
        while 1
            neighbors = false(size(neighbor_mat,1),1);
            for k = 1:length(truth_group);
                neighbors = neighbors | neighbor_mat_copy(:, truth_group(k));
            end
            neighbor_list = find(neighbors);
            in_neighbors = segments.is_in(neighbor_list);
            if isempty(in_neighbors)
                break
            end
            truth_group = [truth_group; in_neighbors];
            
            neighbor_mat_copy(neighbor_list,:) = false;
        end
        
        
        escape_flag = true;
        while escape_flag
            %sample reiteration
            
            seed_group = seed_pick;
            if is_test_file
                escape_flag = false;
            end
            
            
            
            while 1
                %SLASH iteration
            
            end
            
            
        end
        
    end
    
end