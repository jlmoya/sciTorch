#include <wchar.h>
#include "libgw_sciTorch.hxx"
extern "C"
{
#include "libgw_sciTorch.h"
#include "addfunction.h"
}

#define MODULE_NAME L"libgw_sciTorch"

int libgw_sciTorch(wchar_t* _pwstFuncName)
{
    if(wcscmp(_pwstFuncName, L"sciTorch_init") == 0){ addCStackFunction(L"sciTorch_init", &sci_sciTorch_init, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_forward") == 0){ addCStackFunction(L"int_torch_forward", &sci_int_torch_forward, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_list") == 0){ addCStackFunction(L"int_torch_list", &sci_int_torch_list, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_load") == 0){ addCStackFunction(L"int_torch_load", &sci_int_torch_load, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_unload") == 0){ addCStackFunction(L"int_torch_unload", &sci_int_torch_unload, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_unloadall") == 0){ addCStackFunction(L"int_torch_unloadall", &sci_int_torch_unloadall, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_test") == 0){ addCStackFunction(L"int_torch_test", &sci_int_torch_test, MODULE_NAME); }
    if(wcscmp(_pwstFuncName, L"int_torch_props") == 0){ addCStackFunction(L"int_torch_props", &sci_int_torch_props, MODULE_NAME); }

    return 1;
}
