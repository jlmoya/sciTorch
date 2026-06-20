function torch_props(model)
    // Network Architecture
    //
    // Syntax
    //     torch_props(model)
    //
    // Parameters
    //     model : TorchScript model
    //        
    // Description
    //     This function is used to print out the loaded model architecture
    //
    // Examples
    //    model = torch_load(fullpath(torch_path() + "/demos/models/" + 'sciMnist.pt'));
    //    torch_props(model);
    //    torch_unloadall();
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
    int_torch_props(model.ptr);
endfunction
