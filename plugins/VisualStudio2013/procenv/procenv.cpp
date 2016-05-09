// procenv.cpp :
// Get or set environment variable

#include "stdafx.h"
#define BUFSIZE 4096

STDLL stata_call(int argc, char *argv[]){
	//display the full environment?
	if (1==argc || (argc == 2 && strcmp(argv[1], "") == 0)){
		SF_display("Getting env\n");
		LPTCH lpvEnv = GetEnvironmentStrings();

		// If the returned pointer is NULL, exit.
		if (lpvEnv == NULL)	{
			SF_error("Couldn't get env\n");
			return 0;
		}

		// Variable strings are separated by NULL byte, and the block is 
		// terminated by a NULL byte. 
		LPTSTR lpszVariable = (LPTSTR)lpvEnv;

		while (*lpszVariable) {
			char val_buff[BUFSIZE] = { 0 };
			wcstombs(val_buff, lpszVariable, lstrlen(lpszVariable));
			SF_display(val_buff);
			SF_display("\n");
			lpszVariable += lstrlen(lpszVariable) + 1;
		}
		FreeEnvironmentStrings(lpvEnv);
		return 0;
	}
	if (argc != 2){
		SF_error("Must have 1 or 2 arguments.\n");
		return 1;
	}
	BOOL doset = (strcmp(argv[0], "set") == 0);
	if (!doset & (strcmp(argv[0], "get") != 0)){
		SF_error("First argument must be 'get' or 'set'.\n");
		return 1;
	}

	if (doset){
		//Get varname and value by splitting at the first equals
		char *equals_loc;
		if (!(equals_loc = strchr(argv[1], '='))){
			SF_error("Input did not have an equals sign to separate variable name from value.");
			return 1;
		}
		*equals_loc = '\0';
		const char* varname = argv[1];
		const char* varval = equals_loc + 1;

		//set the variable
		char err_msg_buff[BUFSIZE];
		if (!SetEnvironmentVariableA(varname, varval)){
			_snprintf(err_msg_buff, BUFSIZE, "SetEnvironmentVariable failed (%d)\n", GetLastError());
			SF_error(err_msg_buff);
			return 1;
		}
	}
	else{
		//get the char value
		char varvalbuf[BUFSIZE];
		varvalbuf[0] = '\0';
		int s = GetEnvironmentVariableA(argv[1], varvalbuf, BUFSIZE);
		//if failed, could check that s==0 and then GetLastError, but simpler to just return ""
		SF_macro_save("_env_value", varvalbuf);

		//get the wchar_t value
		//looks to always be the same (wasn't sure)
		/*size_t varnamebuflen = strlen(argv[1]) + 1;
		wchar_t *varnamew = new wchar_t[varnamebuflen];
		if (mbstowcs(varnamew, argv[1], varnamebuflen) == (size_t)(-1)) {
			SF_error("Error in plugin argument");
			delete[] varnamew;
			return 1;
		}
		wchar_t varvalbufw[BUFSIZE];
		varvalbufw[0] = '\0';
		s = GetEnvironmentVariableW(varnamew, varvalbufw, BUFSIZE);
		delete[] varnamew;
		size_t varvalbufwlen = wcslen(varvalbufw)+1;
		char *varvalbufw_to_a = new char[varvalbufwlen];
		if (wcstombs(varvalbufw_to_a, varvalbufw, varvalbufwlen) == (size_t)(-1)) {
			SF_error("Error in converting to char");
			delete[] varvalbufw_to_a;
			return 1;
		}

		SF_macro_save("_env_valuew", varvalbufw_to_a);
		delete[] varvalbufw_to_a;*/
	}

	return 0;
}