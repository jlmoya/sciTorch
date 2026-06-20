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

//int sci_int_torch_unload(scilabEnv env, int nin, scilabVar* in, int nopt, scilabOpt opt, int nout, scilabVar* out) {
int sci_int_torch_unload(char *fname, void* pvApiCtx) {
	
	int nFile;
	double *out = NULL;
	int iRows = 0;
	int iCols = 0;

	CheckInputArgument(pvApiCtx, 1, 1);
	CheckOutputArgument(pvApiCtx, 0, 1);

	GetDouble(1, out, iRows, iCols, pvApiCtx);
	nFile = round(*out);

	nFile = nFile - 1;

	if (nFile >= 0 && nFile < MAX_NET_NUM)
	{
		if ((TorchNet[nFile].loaded))
		{
			TorchNet[nFile].model = torch::jit::Module(); TorchNet[nFile].loaded = false;
		}
		else
		{
			Scierror(999, "%s: The %d'th torch model is not opened.\r\n", fname, nFile + 1);
		}
	}
	else
	{
		Scierror(999, "%s: The argument should >=1 and <= %d.\r\n", fname, MAX_NET_NUM);
	}

	return 0;
}


