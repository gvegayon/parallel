// procwait.cpp : 
// For now, no waiting>0 (check if bad (deadlock) to waitsingle if finite time).
//   and maybe should be waiting in Stata not in DLL.

#include "stdafx.h"

#define BUFSIZE 4096

STDLL stata_call(int argc, char *argv[]){
	if (argc != 1){
		SF_error("Expect exactly one argument.\n");
		return 1;
	}
	DWORD dwProcessId = strtol(argv[0], NULL, 10);
	//DWORD waitTime = strtol(argv[1], NULL, 10); //Don't deal with waiting yet.

	HANDLE hProcess = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_INFORMATION, FALSE, dwProcessId);
	if (hProcess == NULL)
		return 0;

	//Should I wait for it to finish?
	DWORD exit_code = 0;
	if (FALSE == GetExitCodeProcess(hProcess, &exit_code)){
		char err_msg_buff[BUFSIZE];
		int le = GetLastError();
		_snprintf(err_msg_buff, BUFSIZE, "GetExitCodeProcess failed (%d)\n", le);
		SF_error(err_msg_buff);
		FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, le,
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), err_msg_buff, BUFSIZE, NULL);
		SF_error(err_msg_buff);

		exit_code = 2;
	}
	else if (STILL_ACTIVE == exit_code)	{
		exit_code = 3;
	}
	else{ //Did finish
		char numberstring[12];
		sprintf(numberstring, "%d", exit_code);
		ST_retcode err;
		if ((err = SF_macro_save("_ret_code", numberstring))) {
			SF_error("Unable to export local 'pid' to Stata\n");
			exit_code = err;
		}
		else{
			exit_code = 0;
		}
	}
	CloseHandle(hProcess);
	return exit_code;
}
