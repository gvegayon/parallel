// procexec_wait.cpp : 
// Start a process

#include "stdafx.h"

#define BIGBUF 32768
#define BUFSIZE 4096
//#define SMALLBUF 256

STDLL stata_call(int argc, char *argv[]){
	wchar_t cmdline[BIGBUF];
	char err_msg_buff[BUFSIZE];
	cmdline[0] = '\0';
	BOOL fSuccess, result;
	DWORD dwFlags = 0, exitCode;
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

	WaitForSingleObject(processInformation.hProcess, INFINITE);

	result = GetExitCodeProcess(processInformation.hProcess, &exitCode);

	CloseHandle(processInformation.hProcess);
	CloseHandle(processInformation.hThread);

	if (!result) {
		SF_error("Executed command but couldn't get exit code.\n");
		return 3;
	}

	char numberstring[12];
	sprintf(numberstring, "%d", exitCode);
	if ((err = SF_macro_save("_exitCode", numberstring))) {
		SF_error("Unable to export local 'exitCode' to Stata\n");
		return err;
	}

	return 0;
}

