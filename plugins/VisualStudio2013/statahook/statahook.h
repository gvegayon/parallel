// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the STATAHOOK_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// STATAHOOK_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef STATAHOOK_EXPORTS
#define STATAHOOK_API __declspec(dllexport)
#else
#define STATAHOOK_API __declspec(dllimport)
#endif

extern "C"{
	STATAHOOK_API LRESULT CALLBACK statafocushook(int nCode, WPARAM wParam, LPARAM lParam);
};

