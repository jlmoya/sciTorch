//=============================================================================
// Copyright (C) Tan Chin Luh - 2017 -
// IPCV - Image Processing and Computer Vision Toolbox for Scilab
// http://www.gnu.org/licenses/gpl-2.0.txt
//=============================================================================
//
mode(-1);

function main_builder();
  TOOLBOX_NAME  = "sciTorch";
  TOOLBOX_TITLE = "sciTorch - Machine and Deep Learning Module for Scilab 6";
  toolbox_dir   = get_absolute_file_path("builder.sce");

  // Check Scilab's version
  // =============================================================================
  try
	  v = getversion("scilab");
  catch
	  error(gettext("Scilab 6 or more is required."));
  end

//  if v(2) < 3 then
//	  // new API in scilab 5.3
//	  error(gettext('Scilab 5.3 or more is required.'));  
//  end
  
  // Check modules_manager module availability
  // =============================================================================
  if ~isdef('tbx_build_loader') then
    error(msprintf(gettext('%s module not installed.'), 'modules_manager'));
  end

  // Action
  // =============================================================================
  tbx_builder_macros(toolbox_dir);
  tbx_builder_gateway(toolbox_dir);
  tbx_builder_help(toolbox_dir);
  tbx_build_loader(toolbox_dir);
  tbx_build_cleaner(toolbox_dir); 
endfunction
// =============================================================================
main_builder();
clear main_builder;
// =============================================================================

