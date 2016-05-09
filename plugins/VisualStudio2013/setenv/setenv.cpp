// Opposite of -local x : environment VAR-
// Useful for setting things up for spawned processes (as they inherit env), in which case return to normal after spawn
//  (when the process is Stata this is especially useful as you can set STATATMP which can't be set in the program).
// TODO: add getter

#include "stdafx.h"
#define BUFSIZE 4096

STDLL stata_call(int argc, char *argv[]){
	if (argc != 2){
		SF_error("Must have 2 arguments.\n");
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
		char varvalbuf[BUFSIZE];
		varvalbuf[0] = '\0';
		int s = GetEnvironmentVariableA(argv[1], varvalbuf, BUFSIZE);
		//if failed, could check that s==0 and then GetLastError, but simpler to just return ""
		SF_macro_save("_env_value", varvalbuf);
	}

	return 0;
}