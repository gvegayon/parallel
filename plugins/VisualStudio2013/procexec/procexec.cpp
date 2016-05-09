// procexec.cpp : 
// Start a process

#include "stdafx.h"

#define BIGBUF 32768
#define BUFSIZE 4096
//#define SMALLBUF 256

STDLL stata_call(int argc, char *argv[]){
	wchar_t cmdline[BIGBUF];
	char err_msg_buff[BUFSIZE];
	cmdline[0] = '\0';
	BOOL fSuccess;
	DWORD dwFlags = 0;
	double st_scalar;
	ST_retcode err = 0;

	//SF_display("Attempting to run ");
	for (int i = 0; i < argc; i++){
		//SF_display(argv[i]);
		size_t strlen = mbstowcs(NULL, argv[i], 0) + 1;
		wchar_t *lpfile = new wchar_t[strlen];
		size_t size = mbstowcs(lpfile, argv[i], strlen);
		if (size == (size_t)(-1)) {
			SF_error("Error in plugin argument");
			return 1;
		}
		else{
			wcscat(cmdline, lpfile);
		}
		delete[] lpfile;
	}
	//SF_display("\n");

	STARTUPINFO startupInfo = { 0 };
	startupInfo.cb = sizeof(startupInfo);

	//Should the process be hidden?
	if (!SF_scal_use("PROCEXEC_HIDDEN", &st_scalar) && (st_scalar >= 1)){
		startupInfo.dwFlags = STARTF_USESHOWWINDOW | STARTF_FORCEOFFFEEDBACK; //don't have mousewheel
		startupInfo.wShowWindow = SW_SHOWMINNOACTIVE; //similar SW_SHOWMINNOACTIVE~SW_HIDE

		//Spawning Stata's still like to steal the focus, so can put in "hidden desktop"
		if (st_scalar >= 2){
			//Try to put the new window in a hidden desktop?
			//HDESK initdesk = GetThreadDesktop(GetCurrentThreadId());
			HDESK desktop = CreateDesktop(_T("hiddenDesktop"), NULL, NULL, 0, DESKTOP_CREATEWINDOW, NULL);
			OpenDesktop(_T("hiddenDesktop"), 0, TRUE, GENERIC_ALL);
			//SetThreadDesktop(desktop);
			//HDESK curdesk = GetThreadDesktop(GetCurrentThreadId());
			//printf("desktop: %x %x\n", curdesk, desktop);
			startupInfo.lpDesktop = _T("hiddenDesktop");
		}
	}

	//Should the process be high_priority?
	if (!SF_scal_use("PROCEXEC_ABOVE_NORMAL_PRIORITY", &st_scalar) && (1 == (int)st_scalar)){
		dwFlags = ABOVE_NORMAL_PRIORITY_CLASS; //NORMAL_PRIORITY_CLASS is assumed
	}

#ifdef UNICODE
	dwFlags = dwFlags | CREATE_UNICODE_ENVIRONMENT;
#endif

	//startupInfo.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE); //remap stdout? (On windows doesn't help because mine goes nowhere)

	PROCESS_INFORMATION processInformation;
	fSuccess = CreateProcess(NULL, cmdline, NULL, NULL, FALSE, dwFlags, NULL, NULL, &startupInfo, &processInformation);
	if (!fSuccess){
		int le = GetLastError();
		_snprintf(err_msg_buff, BUFSIZE, "CreateProcess failed (%d)\n", le);
		SF_error(err_msg_buff);
		FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, le,
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), err_msg_buff, BUFSIZE, NULL);
		SF_error(err_msg_buff);
		return 2;
	}


	//Focus is briefly stolen (around action 26 of the testhook.log).
	//I've prevented whichever actions I could. 
	//If I prevent any of the createwindows, then STata crashes
	//If I modify the createwindow struct then it crashes.
	//Possibly I could determine which call actually does it 
	// (it might not even be one I catch with CBT, but others like DEBUG don't seem to allow prevention)
	// but not sure I could do anything if I do.
	//Has to be in a separate DLL because otherwise complains (and needs to be in a DLL because
	// it's a global hook (as in, not in this address space) http://www.delphigroups.info/2/18/406068.html).
	/*HMODULE dll = LoadLibrary(TEXT("statahook.dll"));
	//HHOOK hhookSysMsg = 0;
	char buf[SMALLBUF];
	if (dll == NULL){
	SF_error("Can't find DLL");
	return -1;
	}
	HOOKPROC addr = (HOOKPROC)GetProcAddress(dll, "statafocushook");
	if (addr == NULL){
	int le = GetLastError();
	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, le,
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, SMALLBUF, NULL);
	SF_error(buf);
	FreeLibrary(dll);
	return -1;
	}
	DWORD tid = processInformation.dwThreadId;

	Sleep(100); //The thread needs to have created some basic stuff before we can hook it.
	hhookSysMsg = SetWindowsHookEx(WH_CBT, addr, dll, tid);
	if (!hhookSysMsg){
	int le = GetLastError();
	_snprintf(err_msg_buff, BUFSIZE, "SetWindowsHookEx failed (%d). PID=%d. DLL=%d\n", le, tid, dll);
	SF_error(err_msg_buff);
	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, le,
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);
	SF_error(buf);
	return 1;
	}
	else{
	_snprintf(err_msg_buff, BUFSIZE, "SetWindowsHookEx succeeded. PID=%d. DLL=%d\n", tid, dll);
	SF_error(err_msg_buff);
	}
	FreeLibrary(dll); //as originally at end of function
	*/

	CloseHandle(processInformation.hProcess);
	CloseHandle(processInformation.hThread);

	char numberstring[12];
	sprintf(numberstring, "%d", processInformation.dwProcessId);
	if ((err = SF_macro_save("_pid", numberstring))) {
		SF_error("Unable to export local 'pid' to Stata\n");
		return err;
	}

	return 0;
}

