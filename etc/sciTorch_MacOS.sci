function sciTorch_MacOS(root_tlbx, TORCH_LIBS)
    // macOS (arm64) port 2026.
    // The gateway dylib (sci_gateway/cpp/libgw_sciTorch.dylib) was linked with an
    // @loader_path-relative rpath to the bundled libTorch
    // (thirdparty/libtorch/Darwin/arm64/lib) and an rpath to IPCV's OpenCV, so all
    // native dependencies are resolved automatically when the gateway is loaded.
    // Nothing to link here (unlike Linux/Windows which preload the torch DLLs).
endfunction
