function y = torch_list()
    // Loaded Models List
    //
    // Syntax
    //     y = torch_list()
    //
    // Parameters
    //     y : Loaded models in Scilab environment
    //        
    // Description
    //    This function used to check the number of loaded model in Scilab. 
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
        
    y = int_torch_list();
endfunction
