/***********************************************************************
* sciTorch - Machine and Deep Learning Module for Scilab 6
* Original work Copyright (C) 2019  Tan Chin Luh
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
***********************************************************************/


#include <Scierror.h>
#include <sciprint.h>
#include <api_scilab.h>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

// Scilab core_math.h defines Min/Max/Abs as function-like macros that collide
// with libTorch symbol names (ATen interned_strings). Undefine before torch.
#ifdef Min
#undef Min
#endif
#ifdef Max
#undef Max
#endif
#ifdef Abs
#undef Abs
#endif
#include <torch/torch.h>
#include <torch/script.h>
#include <opencv2/opencv.hpp>
//#include "C:/Program Files/scilab-6.0.2/contrib/IPCV/sci_gateway/cpp/gw_ipcv.h"
# ifdef _WIN64
  # include <gw_ipcv.h>
# else
  # include <libgw_ipcv.h>
#endif

#define MAX_NET_NUM 3

using namespace std;
using namespace cv;

typedef struct TorchNetwork {
	torch::jit::script::Module model;
	bool loaded = false;
	bool on_mps = false;
} TorchNetwork;

extern TorchNetwork TorchNet[MAX_NET_NUM];

extern "C" 
{
	//int sci_int_scitorch_forward(char * fname, void* pvApiCtx);
	int GetImage(int nPos, Mat& new_img, void* pvApiCtx);
	int matdata2scidata(Mat &pImage, void *pMatData);
	int scidata2matdata(Mat &pImage, void *pMatData);
	int GetImage(int nPos, Mat& new_img, void* pvApiCtx);
	int SetImage(int nPos, Mat& new_img, void* pvApiCtx);
	int GetString(int nPos, char *&pstName, void* pvApiCtx);
	int SetString(int nPos, char *&pstName, void* pvApiCtx);
	int GetDouble(int nPos, double *&pstdata, int& iRows, int& iCols, void* pvApiCtx);
	int GetDouble2(int nPos, double *&pstdata, int& iRows, int& iCols, void* pvApiCtx);
	int SetDouble(int nPos, double *&pstdata, int& iRows, int& iCols, void* pvApiCtx);
	//int sci_int_mnist(char * fname, void* pvApiCtx);
	////int sci_int_loadmnist(char * fname, void* pvApiCtx);
	//int sci_int_loadmnist(char* fname, void* pvApiCtx);
	int sci_sciTorch_init(char* fname, void* pvApiCtx);
	//int sci_int_loadmodel(char* fname, void* pvApiCtx);
	int sci_int_torch_load(char *fname, void* pvApiCtx);
	int sci_int_torch_unload(char *fname, void* pvApiCtx);
	int sci_int_torch_unloadall(char *fname, void* pvApiCtx);
	int sci_int_torch_list(char *fname, void* pvApiCtx);
	int sci_int_torch_props(char *fname, void* pvApiCtx);
	int sci_int_torch_forward(char *fname, void* pvApiCtx);
	int sci_int_torch_test(char *fname, void* pvApiCtx);
	
}

