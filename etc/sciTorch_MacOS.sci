function sciTorch_MacOS(root_tlbx, TORCH_LIBS)
    // macOS (arm64) port 2026.
    // The gateway dylib (sci_gateway/cpp/libgw_sciTorch.dylib) was linked with
    // @loader_path-relative rpaths to the bundled libTorch
    // (thirdparty/libtorch/Darwin/arm64/lib) AND the bundled OpenCV/ffmpeg closure
    // (thirdparty/opencv/Darwin/arm64/lib), so all native dependencies are resolved
    // automatically when the gateway is loaded -- self-contained, no dependency on
    // any other Scilab toolbox/app bundle being present on disk.
    // Nothing to link here (unlike Linux/Windows which preload the torch DLLs).
endfunction
