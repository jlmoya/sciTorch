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

//int sci_int_torch_list(scilabEnv env, int nin, scilabVar* in, int nopt, scilabOpt opt, int nout, scilabVar* out) {
int sci_int_torch_list(char *fname, void* pvApiCtx) {

	int One = 1;
	int i;
	SciErr sciErr;
	int count = 0;
	int offset = 0;

	double dIndices[MAX_NET_NUM];
	double * dIdx = dIndices;


	CheckInputArgument(pvApiCtx, 0, 0);
	CheckOutputArgument(pvApiCtx, 1, 1);

	try {

		for (i = 0; i < MAX_NET_NUM; i++)
		{
			if (TorchNet[i].loaded)
			{
				dIndices[count] = i + 1;
				count++;
			}
		}

		// ToDo : To be replaced with cleaner SetDouble.
		sciErr = createMatrixOfDouble(pvApiCtx, nbInputArgument(pvApiCtx) + 1, count, One, dIdx);
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


