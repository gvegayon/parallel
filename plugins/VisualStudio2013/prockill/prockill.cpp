// prockill.cpp : 
//

#include "stdafx.h"

STDLL stata_call(int argc, char *argv[]){
	if (argc != 1){
		SF_error("Expect exactly one argument.\n");
		return 2;
	}
	DWORD dwProcessId = strtol(argv[0], NULL, 10);
	HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, dwProcessId);
	if (hProcess == NULL)
		return 3;

	//137 = SIGKILL http://unix.stackexchange.com/questions/99112/
	BOOL result = TerminateProcess(hProcess, 137);

	CloseHandle(hProcess);
	if (result == 0){
		SF_error("Couldn't kill process.");
		//GetLastError();} //could pass this back, but don't worry.
	}
	return (!result);
}