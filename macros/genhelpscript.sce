// Generate for Network functions

current_path = get_absolute_file_path("genhelpscript.sce");

pMacrosAll = fullpath(current_path);
pHelpAll = fullpath(current_path + '/../help/en_US');
files_All = findfiles(pMacrosAll, '*.sci');
for i = 1:size(files_All, '*')
  try
  help_from_sci(pMacrosAll + filesep() + files_All(i), pHelpAll);
    catch
    disp(files_All(i));
    end
end


