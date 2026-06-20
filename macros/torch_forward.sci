function out = torch_forward(model,in)
    // Forward Pass
    //
    // Syntax
    //     out = torch_forward(model,in)
    //
    // Parameters
    //     model : TorchScript model
    //     in : Input image
    //     out : Output of the forward pass
    //        
    // Description
    //     This function is used to forward pass an image throught a loaded network.    
    //
    // Examples
    //    S = imread(fullpath(torch_path() + "/demos/images/" + "cat.jpg"));
    //    model = torch_load(fullpath(torch_path() + "/demos/models/" + "sciGooglenet.pt"));
    //    S2 = im2double(S);
    //    
    //    m2 = torch_broadcast([0.485, 0.456, 0.406],S);
    //    s2 = torch_broadcast([0.229, 0.224, 0.225],S);
    //    
    //    // Normalized
    //    S3 = (S2 - m2)./s2;
    //    
    //    out = torch_forward(model,S3);
    //    
    //    // Top-1
    //    [V,I] = max(out);
    //    str = mgetl(fullpath(torch_path() + "/demos/models/" + "classification_classes_ILSVRC2012.txt"));
    //    disp(str(I));
    //    
    //    // Top-5
    //    [maxV,maxI] = gsort(out);
    //    disp(str(maxI(1:5)));
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
    out = int_torch_forward(model.ptr,in);
    
endfunction
