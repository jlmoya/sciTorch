// -------------------------------------------------------------------------
// sciTorch - Scilab libTorch Interface
// Copyright (C) 2019 - ByteCode - Tan Chin Luh
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
// -------------------------------------------------------------------------
//
function builder_gateway_cpp()

        gw_cpp_path = get_absolute_file_path('builder_gateway_cpp.sce');

    // This line added for integrating with custom C/C++ code
    // includes_src_cpp = get_absolute_file_path("builder_gateway_cpp.sce") + "../../src/cpp";
    includes_src_cpp = '';

    // Contructing tables
    gw_cpp_files = findfiles(gw_cpp_path, '*.cpp');
    scifunctions_name = gw_cpp_files(grep(gw_cpp_files, 'sci_'));
    scifunctions_name = strsubst(scifunctions_name, 'sci_', '');
    scifunctions_name = strsubst(scifunctions_name, 'percent', '%');
    scifunctions_name = strsubst(scifunctions_name, '.cpp', '');

    cppfunctions_name = gw_cpp_files(grep(gw_cpp_files,'sci_'));
    cppfunctions_name = strsubst(cppfunctions_name, '.cpp', '');

    gw_tables = [scifunctions_name, cppfunctions_name];
    //temp_str = ['csci6' 'csci' 'csci']';  // Testing for csci6 interface
    temp_str = repmat('csci',size(scifunctions_name,1),1);
    
    gw_tables(:,3) = temp_str;
    opencv_libs = [];

    inter_cc = "";
    // Platform dependent setting. Split to 3 systems for easy maintenance
    if getos() == 'Darwin' then  // MacOS (Apple Silicon / arm64) -- macOS port 2026
        gw_cpp_files = [gw_cpp_files; "common.h"];           // Add in common header
        gw_cpp_files(gw_cpp_files == 'dllsciTorch.cpp') = []; // windows-only symbol loader

        // IPCV headers/import-lib are still needed to REBUILD this gateway from
        // source (opencv2/opencv.hpp + the IPCV-vendored OpenCV .dylib to link
        // against) -- the runtime artifact itself is self-contained (see the rpath
        // comment below), but a source rebuild still needs IPCV present. Prefer
        // asking the running session (portable across machines); if IPCV isn't
        // loadable in THIS session (e.g. its own bundled OpenCV/ffmpeg has the same
        // class of broken-absolute-path fragility we're fixing here, or it's just
        // not loaded), fall back to this machine's known install so the build isn't
        // blocked on a completely unrelated toolbox's own defects.
        try
            [m, ipcv_path] = libraryinfo('ipcvlib');   // IPCV macro path
        catch
            ipcv_path = "/Applications/scilab-2026.1.0.app/Contents/share/scilab/contrib/IPCV/4.5.0.2/macros";
            warning("builder_gateway_cpp: ipcvlib not loadable in this session; falling back to " + ipcv_path);
        end
        torch_tp_path  = fullpath(gw_cpp_path + "/../../thirdparty");
        torch_arch     = "arm64";

        TORCH_ROOT     = fullpath(torch_tp_path + "/libtorch/Darwin/" + torch_arch);
        TORCH_INCLUDE  = fullpath(TORCH_ROOT + "/include");
        TORCH2_INCLUDE = fullpath(TORCH_ROOT + "/include/torch/csrc/api/include");
        TORCH_LIB      = fullpath(TORCH_ROOT + "/lib");
        OPENCV_ROOT    = fullpath(ipcv_path + "/../thirdparty/Darwin/" + torch_arch);
        OPENCV_INCLUDE = fullpath(OPENCV_ROOT + "/include/opencv4");
        OPENCV_LIB     = fullpath(OPENCV_ROOT + "/lib");
        IPCV_INCLUDE   = fullpath(ipcv_path + "/../sci_gateway/cpp");

        // libTorch 2.5.1 requires C++17. These flags go to both CFLAGS and CXXFLAGS,
        // so the C compiler would reject -std=c++17; we force CC into C++ mode below.
        inter_cflags = " -std=c++17 -stdlib=libc++";
        inter_cflags = inter_cflags + " -I" + TORCH_INCLUDE;
        inter_cflags = inter_cflags + " -I" + TORCH2_INCLUDE;
        inter_cflags = inter_cflags + " -I" + OPENCV_INCLUDE;
        inter_cflags = inter_cflags + " -I" + IPCV_INCLUDE;
        // libTorch+clang21 clash: ATen specializes std::is_arithmetic -> downgrade to warning
        inter_cflags = inter_cflags + " -Wno-error=invalid-specialization -Wno-invalid-specialization";

        // Link libTorch + OpenCV; rpath to libtorch is @loader_path-relative so it
        // resolves both in the build tree and after deploy to contrib. OpenCV's rpath
        // is ALSO @loader_path-relative, into sciTorch's own vendored copy
        // (thirdparty/opencv/Darwin/arm64/lib) rather than IPCV's install -- sciTorch
        // must not depend on another toolbox's app bundle still being on disk at
        // runtime. OPENCV_INCLUDE/-L still resolve against IPCV's headers/import lib
        // at BUILD time only (rebuilding from source still needs IPCV installed).
        inter_ldflags = " -std=c++17 -stdlib=libc++";
        inter_ldflags = inter_ldflags + " -L" + TORCH_LIB + " -ltorch -ltorch_cpu -lc10";
        inter_ldflags = inter_ldflags + " -Wl,-rpath,@loader_path/../../thirdparty/libtorch/Darwin/" + torch_arch + "/lib";
        inter_ldflags = inter_ldflags + " -L" + OPENCV_LIB + " -lopencv_world -Wl,-rpath,@loader_path/../../thirdparty/opencv/Darwin/" + torch_arch + "/lib";

        // Force the C compiler into C++ mode so configure's mandatory C-compiler test
        // accepts -std=c++17 (the gateway has no .c files, only .cpp).
        inter_cc = "clang++ -x c++";

        // No extra libs to pre-link()/preload: sciTorch's gateway does NOT call into
        // IPCV's own gateway (libgw_ipcv) -- confirmed via nm -u showing zero undefined
        // symbols referencing it in the built dylib. A stray
        // all_libs = .../libgw_ipcv here (copy-pasted from the IPCV skeleton this
        // toolbox was derived from) used to make ilib_gen_loader emit a link() of
        // libgw_ipcv at the top of loader.sce -- which is ABI-coupled to whatever
        // Scilab app bundle IPCV happens to be installed in, fails on any other build,
        // and silently aborts the whole gateway load before addinter() ever runs. See
        // sci_gateway/cpp/loader.sce.
        all_libs = [];
    elseif getos() == "Linux" then  // Linux

        gw_cpp_files = [gw_cpp_files; "common.h"];
        gw_cpp_files(gw_cpp_files == 'dllsciTorch.cpp') = [];
        [m,ipcv_path]=libraryinfo('ipcvlib');   // To get path for IPCV - macro path
        torch_tp_path = fullpath(gw_cpp_path + "/../../thirdparty");


        TORCH_INCLUDE = fullpath(torch_tp_path + "/libtorch/Linux/CPU/include");
        TORCH2_INCLUDE = fullpath(torch_tp_path + "/libtorch/Linux/CPU/include/torch/csrc/api/include");
        OPENCV_INCLUDE = fullpath(ipcv_path + "/../thirdparty/opencv/Linux/include");
        IPCV_INCLUDE = fullpath(ipcv_path + "/../sci_gateway/cpp");

        //inter_cflags = ilib_include_flag([OPENCV_INCLUDE,TORCH_INCLUDE, includes_src_cpp]);
        inter_cflags = ' -I'+OPENCV_INCLUDE;
        inter_cflags = inter_cflags + ' -I'+TORCH_INCLUDE;
        inter_cflags = inter_cflags + ' -I'+TORCH2_INCLUDE;
        inter_cflags = inter_cflags + ' -I'+IPCV_INCLUDE;
        //inter_cflags = inter_cflags + ' -D_GLIBCXX_USE_CXX11_ABI=0';   // This is for LIBTorch -no more, for future reference
        inter_ldflags = " -std=c++11";
        opencv_libs = [];
        
        // No extra libs to pre-link()/preload -- see the Darwin branch above for why
        // an all_libs = .../libgw_ipcv here would resurrect the loader.sce bug.
        all_libs = [];

    else // Windows
        // Include paths, including torch, opencv and IPCV path
        gw_cpp_files = [gw_cpp_files; "common.h"];
        [m,ipcv_path]=libraryinfo('ipcvlib');   // To get path for IPCV - macro path
        torch_tp_path = fullpath(gw_cpp_path + "../../thirdparty");
        
        TORCH_INCLUDE = fullpath(torch_tp_path + "/libtorch/windows/CPU/include");
        TORCH2_INCLUDE = fullpath(torch_tp_path + "/libtorch/windows/CPU/include/torch/csrc/api/include");
        OPENCV_INCLUDE = fullpath(ipcv_path + "/../thirdparty/opencv/windows/include");
        IPCV_INCLUDE = fullpath(ipcv_path + "/../sci_gateway/cpp");
        
        inter_cflags = ilib_include_flag([OPENCV_INCLUDE TORCH_INCLUDE, TORCH2_INCLUDE,IPCV_INCLUDE]); 
        inter_ldflags = " -std=c++11";        

        // No extra libs to pre-link()/preload -- see the Darwin branch above for why
        // an all_libs = .../gw_ipcv here would resurrect the loader.sce bug.
        all_libs = [];

    end

    tbx_build_gateway('gw_sciTorch', ..
    gw_tables, ..
    gw_cpp_files, ..
    gw_cpp_path, ..
    all_libs, ..
    inter_ldflags, ..
    inter_cflags, ..
    "", ..
    inter_cc);

endfunction
// ====================================================================
builder_gateway_cpp();
clear builder_gateway_cpp;
// ====================================================================


















































