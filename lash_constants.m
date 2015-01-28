function C = lash_constants()

    C.cube_dir = '/omelette/2/omniweb_data/';
    C.label_dir = '/omelette/5/omniData/e2198_reconstruction/mesh.omni.files/';
    C.affinity_dir = '/omelette/5/omniData/e2198_affin.764/';
    
%     C.training_dir = '~/neoLASH/training_data/';
    C.training_dir = '../training_data/';
    
    C.moment_depth_generation = 5;
    C.max_net_inputs = 10000;
    
    C.translation_fxn_name = 'translate_moment';
end