// Starts a command, waits for it to finish, and returns the exitcode.
// If scalar PROCEXEC_HIDDEN >= 1 then the process will be auto-minimized
// If scalar PROCEXEC_HIDDEN == 2 then the process will hidden (in a "hidden" desktop; can be killed by knowing the PID)
// If scalar PROCEXEC_ABOVE_NORMAL_PRIORITY=1 then new process will have ABOVE_NORMAL_PRIORITY (default is NORMAL)
program procexecw, rclass
	version 11.0
	syntax anything(equalok everything)
	plugin call procexecw_plug, `"`anything'"'
	return scalar exitcode = `exitCode'
end

cap program procexecw_plug, plugin using("procexecw.plugin")
