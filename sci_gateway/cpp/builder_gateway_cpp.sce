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
        // macOS: link the SYSTEM OpenCV (Homebrew) -- the SAME copy scicv uses -- so
        // both toolboxes share ONE OpenCV in a single process. sciTorch needs only
        // Mat<->tensor conversion (cv::Mat / cv::imread; 7 symbols, core + imgcodecs),
        // never highgui or videoio. The old vendored libopencv_world 4.5.0 was a
        // monolithic all-modules build: it pulled highgui's CVWindow/CVView/CVSlider and
        // videoio's CaptureDelegate ObjC classes into the process, where they collided
        // with scicv's OpenCV 5.0.0 and risked dispatching scicv's imshow/VideoCapture
        // (used 441x) to sciTorch's stale 4.5.0 classes -- the "mysterious crashes" the
        // ObjC runtime warns about. Resolved through pkg-config (module opencv5), so an
        // OpenCV upgrade is picked up here with no edit. PKG_CONFIG_PATH is pinned to the
        // Homebrew keg because opencv5.pc lives under opt/opencv, not the default path.
        OPENCV_PCENV   = "PKG_CONFIG_PATH=/opt/homebrew/opt/opencv/lib/pkgconfig ";
        OPENCV_CFLAGS  = stripblanks(unix_g(OPENCV_PCENV + "pkg-config --cflags opencv5"));
        OPENCV_LIBDIR  = stripblanks(unix_g(OPENCV_PCENV + "pkg-config --variable=libdir opencv5"));
        if OPENCV_CFLAGS == "" | OPENCV_LIBDIR == "" then
            error("builder_gateway_cpp: pkg-config could not resolve opencv5 -- is Homebrew opencv installed? (brew install opencv)");
        end
        IPCV_INCLUDE   = fullpath(ipcv_path + "/../sci_gateway/cpp");

        // libTorch 2.5.1 requires C++17. These flags go to both CFLAGS and CXXFLAGS,
        // so the C compiler would reject -std=c++17; we force CC into C++ mode below.
        inter_cflags = " -std=c++17 -stdlib=libc++";
        inter_cflags = inter_cflags + " -I" + TORCH_INCLUDE;
        inter_cflags = inter_cflags + " -I" + TORCH2_INCLUDE;
        inter_cflags = inter_cflags + " " + OPENCV_CFLAGS;
        inter_cflags = inter_cflags + " -I" + IPCV_INCLUDE;
        // libTorch+clang21 clash: ATen specializes std::is_arithmetic -> downgrade to warning
        inter_cflags = inter_cflags + " -Wno-error=invalid-specialization -Wno-invalid-specialization";

        // Link libTorch + OpenCV. libTorch stays vendored: its rpath is @loader_path-
        // relative so it resolves in the build tree and after deploy to contrib.
        // OpenCV now comes from Homebrew and needs NO rpath -- its dylibs carry absolute
        // install_names (/opt/homebrew/opt/opencv/lib/libopencv_*.500.dylib), the same
        // way scicv links them, so both toolboxes resolve to the one physical copy.
        // Only the modules sciTorch actually uses are linked: core (cv::Mat, fastFree),
        // imgproc, imgcodecs (cv::imread) -- deliberately NOT highgui/videoio, whose
        // ObjC classes were the entire cause of the collision.
        inter_ldflags = " -std=c++17 -stdlib=libc++";
        inter_ldflags = inter_ldflags + " -L" + TORCH_LIB + " -ltorch -ltorch_cpu -lc10";
        inter_ldflags = inter_ldflags + " -Wl,-rpath,@loader_path/../../thirdparty/libtorch/Darwin/" + torch_arch + "/lib";
        inter_ldflags = inter_ldflags + " -L" + OPENCV_LIBDIR + " -lopencv_core -lopencv_imgproc -lopencv_imgcodecs";

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

    // macOS: re-sign the freshly linked gateway with a fresh ad-hoc signature.
    // The linker's own ad-hoc signature ("linker-signed") on this dylib passes
    // `codesign --verify` yet is REJECTED by AMFI at load time with a CODESIGNING
    // "Invalid Page" fault (EXC_BAD_ACCESS / SIGKILL) -- which takes down the whole
    // Scilab process the instant the gateway is link()'d. It surfaced when this gateway
    // began pulling Homebrew OpenCV's larger dependency chain (openblas + gcc fortran)
    // alongside libTorch; the fresh signature below loads cleanly. This is a no-op on a
    // gateway that was already fine, so it is safe to run unconditionally on Darwin.
    if getos() == 'Darwin' then
        gw_dylib = fullpath(gw_cpp_path + "/libgw_sciTorch" + getdynlibext());  // getdynlibext() includes the dot
        if isfile(gw_dylib) then
            unix_g("codesign --remove-signature " + """" + gw_dylib + """" + " 2>/dev/null; " + ..
                   "codesign --force --sign - --timestamp=none " + """" + gw_dylib + """");
        end
    end

endfunction
// ====================================================================
builder_gateway_cpp();
clear builder_gateway_cpp;
// ====================================================================


















































