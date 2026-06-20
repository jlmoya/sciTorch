#ifndef __LIBGW_SCITORCH_GW_HXX__
#define __LIBGW_SCITORCH_GW_HXX__

#ifdef _MSC_VER
#ifdef LIBGW_SCITORCH_GW_EXPORTS
#define LIBGW_SCITORCH_GW_IMPEXP __declspec(dllexport)
#else
#define LIBGW_SCITORCH_GW_IMPEXP __declspec(dllimport)
#endif
#else
#define LIBGW_SCITORCH_GW_IMPEXP
#endif

extern "C" LIBGW_SCITORCH_GW_IMPEXP int libgw_sciTorch(wchar_t* _pwstFuncName);



#endif /* __LIBGW_SCITORCH_GW_HXX__ */
