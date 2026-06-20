function p = torch_path()

    p = [];
    if isdef('sciTorchlib') then
        [m, mp] = libraryinfo('sciTorchlib');
        p = pathconvert(fullpath(mp + "/../"), %t, %t);
    end

endfunction
