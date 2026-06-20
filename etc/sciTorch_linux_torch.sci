function sciTorch_linux_torch(root_tlbx,TORCH_LIBS)
    // Try to use included precompiled OpenCV
    [a, b] = getversion();
    is_x64 = or(b == 'x64');


    //TORCH_LIBS = "lib" + TORCH_LIBS;
    


    if (is_x64) then
        torchDynLibPath = fullpath(root_tlbx + "/thirdparty/libtorch/" + getos() + "/CPU/lib/");
    else
        error("sciTorch only support 64-bits.")
    end
     
    tmp = pwd();
    cd(torchDynLibPath);

    TORCH_LIBS = ls('*.so');

    for l = 1:size(TORCH_LIBS, '*')
//        pause
        if execstr('link(TORCH_LIBS(l))', 'errcatch') <> 0 then
            bDepsLoaded = %f;
            disp(TORCH_LIBS(l)+' failed');
        else
            disp(TORCH_LIBS(l)+' loaded');
        end
    end
    
    cd(tmp);



endfunction
