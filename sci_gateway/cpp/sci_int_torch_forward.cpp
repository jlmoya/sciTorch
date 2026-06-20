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

#include "common.h"

//int sci_int_torch_forward(scilabEnv env, int nin, scilabVar* in, int nopt, scilabOpt opt, int nout, scilabVar* out) {
int sci_int_torch_forward(char *fname, void* pvApiCtx) {

	SciErr sciErr;
	void* pvPtr = NULL;
	int* piAddr = NULL;
	int iRows = 0;
	int iCols = 0;
	int nFile;
	double *out = NULL;
	Mat image;




	// Check input-output
	CheckInputArgument(pvApiCtx, 2, 2);
	CheckOutputArgument(pvApiCtx, 0, 1);
	try
	{
		// Input 1 : Pointer to the DNN
		GetDouble(1, out, iRows, iCols, pvApiCtx);
		nFile = round(*out);
		nFile -= 1;

		// Input 2 : Image
		GetImage(2, image, pvApiCtx);

		// Error Checking
		if (!TorchNet[nFile].loaded)
		{
			Scierror(999, "%s: Could not load torch model.\n", fname);
			return -1;
		}

		if (image.empty())
		{
			Scierror(999, "%s: Not a valid image\n", fname);
			return -1;
		}

		// ToDo: Consider resizing for network which does not support variable size (model.preprocess = 1, model.inputsize = [rows,cols]
		//cv::resize(src_image, image, cv::Size(224,224), cv::INTER_CUBIC); 
		std::vector<int64_t> sizes = { 1, image.rows, image.cols , image.channels() };

		// ToDo: Choice of different input image datatype. Currently input from Scilab must be converted to double 
		//at::TensorOptions options(at::ScalarType::Byte);// For uint8 image
		at::TensorOptions options(at::ScalarType::Double);// For double image

		// Convert image to torch format
		at::Tensor input = torch::from_blob(image.data, at::IntArrayRef(sizes), options);
		input = input.permute({ 0, 3, 1, 2 }); // convert to CxHxW
		input = input.toType(at::kFloat);
		if (TorchNet[nFile].on_mps) input = input.to(at::kMPS);
		std::vector<torch::jit::IValue> inputs;
		inputs.push_back(input);

		// Forward pass
		//TorchNet[nFile].model.eval();
		at::Tensor output = TorchNet[nFile].model.forward(inputs).toTensor();
		if (TorchNet[nFile].on_mps) output = output.to(at::kCPU);

		// Output to Scilab = To be simplified.
		double* pdblReal = NULL;
		pdblReal = (double*)malloc(sizeof(double) * output.size(1));

		// Output data to Scilab workspace. Currently only for Image classification until torchvision models has been fully supported by torchscript
		for (int cnt = 0; cnt < output.size(1); cnt++)
		{
			*(pdblReal + cnt) = output[0][cnt].item().to<double>();
		}

		int dims_var[2] = { (int)output.size(0),(int)output.size(1) };
		int *dims;

		dims = dims_var;
		sciErr = createHypermatOfDouble(pvApiCtx, nbInputArgument(pvApiCtx) + 1, dims, 2, pdblReal);
		AssignOutputVariable(pvApiCtx, 1) = nbInputArgument(pvApiCtx) + 1;

	}
	catch (const std::exception& e)
	{

		{ std::string _m(e.what()); if (_m.size() > 800) _m = _m.substr(0,800) + " ...(truncated)"; sciprint("sciTorch error: %s\n", _m.c_str()); }
		int iRet = createScalarDouble(pvApiCtx, nbInputArgument(pvApiCtx) + 1, -1);
		AssignOutputVariable(pvApiCtx, 1) = nbInputArgument(pvApiCtx) + 1;
		return -1;
	}

	return 0;

}


