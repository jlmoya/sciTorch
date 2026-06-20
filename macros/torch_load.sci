function model = torch_load(fn, device)
    // Load Torch Script Model
    //
    // Syntax
    //     model = torch_load(fn);
    //
    // Parameters
    //     fn : filename (.pt) for torchscript model
    //     model : model object
    //        
    // Description
    //    This function used to load the torchscript model
    //
    // Examples
    //    model = torch_load(fullpath(torch_path() + "/demos/models/" + 'sciMnist.pt'));
    //    torch_list()
    //    torch_props(model);
    //    torch_unload(model);
    //    torch_list()
    //
    // See also
    //     torch_load
    //     torch_unload
    //     torch_unloadall
    //     torch_list
    //     torch_props
    //     torch_forward
    //
    // Authors
    //    ByteCode - Tan Chin Luh
    //
    
    if argn(2) < 2 then
        model.ptr = int_torch_load(fn);
    else
        model.ptr = int_torch_load(fn, device);
    end
    model.preprocess = 1;
    model.mean = [0.485, 0.456, 0.406];
    model.std = [0.229, 0.224, 0.225];    
    
endfunction
