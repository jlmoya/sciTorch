function torch_unload(model)
    // Unload Model from Scilab Workspace
    //
    // Syntax
    //     torch_unload(model)
    //
    // Parameters
    //     model : Loaded models in Scilab environment
    //        
    // Description
    //    This function used to unload given loaded model in Scilab. 
    //
    // Examples
    //    model = torch_load(fullpath(torch_path() + "/demos/models/" + "sciGooglenet.pt"));
    //    torch_list()
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
        
    int_torch_unload(model.ptr);
endfunction
