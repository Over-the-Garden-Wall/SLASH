

cube_max = [16 100 100];
while 1
    try
        tic
        r = ceil(rand(1,3).*cube_max);
        create_training_example(r);
        disp('successful trial generation!');
        toc
    catch ME
        disp(ME.message)
        disp('failed trial generation')
        toc
    end
end
        