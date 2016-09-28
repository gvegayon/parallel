#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include "stplugin.h"

        STDLL stata_call(int argc, char *argv[])
        {

		if (argc == 0) {
			SF_error("Missing command line");
			return 198;
		}
		char cmdline[32768];
		cmdline[0] = '\0';
		SF_display("Attempting to run ");
		SF_display(argv[0]);
		for (int i = 1; i < argc; i++){
			SF_display(argv[i]);
			strcat(cmdline, argv[i]);
		}
		SF_display("\n");

		pid_t pid = fork();
		int status = 0;

		switch (pid) {
			case -1:
				SF_error("Error forking process");
				return 198;
				break;
			case 0:
				/* This is the child process */
				execv(argv[0], argv);
				exit(0);
				break;
			default:
				/* This is the parent process */
				waitpid(pid, &status, 0);
				if(WIFEXITED(status)) {
					return WEXITSTATUS(status) ;
				} else {
					SF_error("Process did not exit cleanly");
				}
				break;
		}
	}
