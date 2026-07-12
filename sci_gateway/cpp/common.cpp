/***********************************************************************
* sciTorch - Machine and Deep Learning Module for Scilab 6
*
* GetDouble/GetString/GetImage: sciTorch's gateway .cpp files call these three
* helpers (declared in common.h) to pull arguments off the Scilab stack, but no
* implementation ever shipped in this repo -- they were silently supplied at
* runtime by ALSO link()-ing IPCV's gateway (libgw_ipcv), which happens to
* export functions with these exact names. That cross-toolbox dependency was
* removed (see sci_gateway/cpp/loader.sce / builder_gateway_cpp.sce -- link()ing
* another Scilab install's IPCV build is both version-ABI-fragile and breaks the
* moment that other app bundle is deleted). This file makes sciTorch
* self-contained by implementing the three helpers directly against Scilab's own
* stable api_scilab.h C API instead.
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
***********************************************************************/

#include "common.h"
#include <sci_types.h>

extern "C" int GetDouble(int nPos, double *&pstdata, int& iRows, int& iCols, void* pvApiCtx)
{
    int* piAddr = NULL;
    SciErr sciErr = getVarAddressFromPosition(pvApiCtx, nPos, &piAddr);
    if (sciErr.iErr)
    {
        Scierror(999, "GetDouble: unable to get argument #%d address.\r\n", nPos);
        return 1;
    }

    sciErr = getMatrixOfDouble(pvApiCtx, piAddr, &iRows, &iCols, &pstdata);
    if (sciErr.iErr)
    {
        Scierror(999, "GetDouble: argument #%d is not a matrix of double.\r\n", nPos);
        return 1;
    }

    return 0;
}

extern "C" int GetString(int nPos, char *&pstName, void* pvApiCtx)
{
    int* piAddr = NULL;
    SciErr sciErr = getVarAddressFromPosition(pvApiCtx, nPos, &piAddr);
    if (sciErr.iErr)
    {
        Scierror(999, "GetString: unable to get argument #%d address.\r\n", nPos);
        return 1;
    }

    int iType = 0;
    sciErr = getVarType(pvApiCtx, piAddr, &iType);
    if (sciErr.iErr || iType != sci_strings)
    {
        Scierror(999, "GetString: argument #%d is not a string.\r\n", nPos);
        return 1;
    }

    // getAllocatedSingleString returns a non-zero (int) status, not a SciErr.
    if (getAllocatedSingleString(pvApiCtx, piAddr, &pstName))
    {
        Scierror(999, "GetString: unable to read argument #%d.\r\n", nPos);
        return 1;
    }

    return 0;
}

// Best-effort: not exercised by tbx-smoke (int_torch_forward has no smoke coverage --
// see tbx-smoke/sciTorch.sce's rationale), so this conversion is unverified against a
// real image round trip. Scilab stores an image as imread()/im2double() do: a
// [rows, cols, channels] hypermatrix of doubles (2-D matrix for single-channel/gray),
// COLUMN-major with one contiguous plane per channel, i.e. element (r,c,ch) lives at
// pdblReal[r + c*rows + ch*rows*cols]. OpenCV's Mat is ROW-major with interleaved
// channels, i.e. element (r,c,ch) lives at data[(r*cols+c)*channels + ch]. This
// function transposes between the two layouts; sci_int_torch_forward.cpp then hands
// image.data straight to torch::from_blob as CV_64F, so the Mat must be CV_64FC(n).
extern "C" int GetImage(int nPos, Mat& new_img, void* pvApiCtx)
{
    int* piAddr = NULL;
    SciErr sciErr = getVarAddressFromPosition(pvApiCtx, nPos, &piAddr);
    if (sciErr.iErr)
    {
        Scierror(999, "GetImage: unable to get argument #%d address.\r\n", nPos);
        return 1;
    }

    int* dims = NULL;
    int ndims = 0;
    double* pdblReal = NULL;
    int rows = 0, cols = 0, channels = 1;

    sciErr = getHypermatOfDouble(pvApiCtx, piAddr, &dims, &ndims, &pdblReal);
    if (sciErr.iErr == 0 && ndims >= 2)
    {
        rows = dims[0];
        cols = dims[1];
        channels = (ndims >= 3) ? dims[2] : 1;
    }
    else
    {
        // Not a hypermatrix: fall back to a plain 2-D (single-channel) matrix.
        sciErr = getMatrixOfDouble(pvApiCtx, piAddr, &rows, &cols, &pdblReal);
        if (sciErr.iErr)
        {
            Scierror(999, "GetImage: argument #%d is not a valid image (matrix/hypermatrix of double expected).\r\n", nPos);
            return 1;
        }
        channels = 1;
    }

    if (rows <= 0 || cols <= 0 || channels <= 0)
    {
        Scierror(999, "GetImage: argument #%d has invalid image dimensions.\r\n", nPos);
        return 1;
    }

    new_img.create(rows, cols, CV_64FC(channels));
    for (int r = 0; r < rows; r++)
    {
        double* pRow = new_img.ptr<double>(r);
        for (int c = 0; c < cols; c++)
        {
            for (int ch = 0; ch < channels; ch++)
            {
                pRow[c * channels + ch] = pdblReal[r + c * rows + ch * rows * cols];
            }
        }
    }

    return 0;
}
