function torch_unloadall()
    // Unload All Model from Scilab Workspace
    //
    // Syntax
    //     torch_unloadall()
    //
    // Parameters
    //        
    // Description
    //    This function used to unload all loaded models in Scilab. 
    //
    // Examples
    //    model = torch_load(fullpath(torch_path() + "/demos/models/" + "sciGooglenet.pt"));
    //    torch_list()
    //    torch_unloadall;
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
    int_torch_unloadall;
endfunction
