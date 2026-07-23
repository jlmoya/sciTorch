function sciTorch_MacOS(root_tlbx, TORCH_LIBS)
    // macOS (arm64) port 2026.
    // The gateway dylib (sci_gateway/cpp/libgw_sciTorch.dylib) is linked with an
    // @loader_path-relative rpath to the bundled libTorch
    // (thirdparty/libtorch/Darwin/arm64/lib). OpenCV is NO LONGER bundled: the
    // gateway links the system Homebrew OpenCV 5.0.0 by absolute path (the same copy
    // scicv uses), so the two toolboxes share one OpenCV instead of colliding on
    // duplicate highgui/videoio ObjC classes. libTorch resolves via its rpath and
    // OpenCV via its absolute install_names when the gateway is loaded.
    // Nothing to link here (unlike Linux/Windows which preload the torch DLLs).
endfunction
