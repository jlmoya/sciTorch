function Iout = torch_broadcast(x,Iin)
    // Variable Broadcasting
    //
    // Syntax
    //     Iout = torch_broadcast(x,Iin);
    //
    // Parameters
    //     x : Vector for which to be broadcasted to the size of Iin
    //     Iin : Input image
    //     Iout : Output for the broadcasted variable.
    //        
    // Description
    //    This function used to broadcast the varible to match the input size for arithmetic operations.
    //
    // Examples
    //    S = imread(fullpath(torch_path() + "/demos/images/" + 'cat.jpg'));
    //    S2 = im2double(S);
    //    m = [0.485, 0.456, 0.406];
    //    m2 = torch_broadcast(m,S);
    //    disp(size(m));
    //    disp(size(m2));
    //    S3 = S2 - m2;
    //    subplot(121); imshow(S2);
    //    subplot(122); imshow(S3);
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
    
// This function should be smarter
//m=[0.485, 0.456, 0.406]
//s=[0.229, 0.224, 0.225]
x2 = matrix(x,[1 1 3])
Iout = repmat(x2,size(Iin)(1:2))
    
endfunction
