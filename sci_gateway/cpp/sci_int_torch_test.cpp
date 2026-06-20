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
#include <torch/script.h>               // One-stop header.
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include <chrono>
#include <iostream>
#include <memory>
using namespace std;
using namespace std::chrono;

/***************************************************
* this function should be called when sciTorch is loaded
***************************************************/
//int sci_int_scitorch_load(scilabEnv env, int nin, scilabVar* in, int nopt, scilabOpt opt, int nout, scilabVar* out) {
int sci_int_torch_test(char *fname, void* pvApiCtx) {
	


		int input_image_size = 224;
		int batch_size = 1;

		// Deserialize the ScriptModule from a file using torch::jit::load().
		//torch::jit::script::Module module
		//std::shared_ptr<torch::jit::script::Module> module = torch::jit::load("resnet18.pt");
		torch::jit::script::Module module = torch::jit::load("resnet18.pt");

		// Read input image
		cv::Mat origin_image = cv::imread("cat.jpg", 1);

		// Preprocess image (resize, put on GPU)
		cv::Mat resized_image;
		cv::cvtColor(origin_image, resized_image, cv::COLOR_RGB2BGR);
		cv::resize(resized_image, resized_image, cv::Size(input_image_size, input_image_size));

		cv::Mat img_float;
		resized_image.convertTo(img_float, CV_32F, 1.0 / 255);

		while (true) {
			std::vector<at::Tensor> inputs_vec;
			for (int i = 0; i < 8; i++) {
				//auto img_tensor = torch::from_blob(img_float.data, {1, input_image_size, input_image_size, 3}).to(torch::kCUDA)
				auto img_tensor = torch::from_blob(img_float.data, { 1, input_image_size, input_image_size, 3 }	, torch::kFloat);
				img_tensor = img_tensor.permute({ 0, 3, 1, 2 });
				img_tensor[0][0] = img_tensor[0][0].sub(0.485).div(0.229);
				img_tensor[0][1] = img_tensor[0][1].sub(0.456).div(0.224);
				img_tensor[0][2] = img_tensor[0][2].sub(0.406).div(0.225);
				//auto img_var = torch::autograd::make_variable(img_tensor, false);
				inputs_vec.push_back(img_tensor);
			}

			// Create a vector of inputs.
			std::vector<torch::jit::IValue> inputs;
			//for (int i = 0; i < 8; i++) {
			//inputs.push_back(img_var.to(at::kCUDA));
			at::Tensor input_ = torch::cat(inputs_vec);
			//inputs.push_back(input_.to(at::kCUDA));
			inputs.push_back(input_);
			//inputs.push_back(torch::ones({10, 3, 224, 224}).to(at::kCUDA));
			//}

			// Execute the model and turn its output into a tensor.
			torch::Tensor output;
			auto duration = duration_cast<milliseconds>(std::chrono::high_resolution_clock::now() - std::chrono::high_resolution_clock::now());
			auto start = std::chrono::high_resolution_clock::now();
			output = module.forward(inputs).toTensor();
			auto end = std::chrono::high_resolution_clock::now();
			duration = duration_cast<milliseconds>(end - start);
			//std::cout << output[0] << '\n';
			for (int i = 0; i<output.size(0); i++) {
				at::Tensor max_ind = at::argmax(output[i]);
				//std::cout << "class_id: " << i << " :" << max_ind.item<int>() << std::endl;
				sciprint("class_id: %i\n", max_ind.item<int>());
			}

			// at::Tensor max_ind = at::argmax(output);
			// std::cout << "class_id: " << max_ind.item<int>() << std::endl;
			// std::cout << "Time take for forward pass: " << duration.count() << " ms" << std::endl;
			break;
		}
		sciprint("Done\n");
		return 0;

}


