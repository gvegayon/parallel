//Kills a process by it's Process ID
//On Linux send SIGTERM (kill's default) if local, otherwise SIGKILL
program prockill
	version 11.0
	syntax anything(everything) [, connection(string)]
	
	if (c(os) == "Windows") {
		plugin call prockill_plug, `"`anything'"'
	}
	else{ //sends signal SIGTERM by default
		if "`connection'"!="" local kill_opt "-9"
		shell `connection' kill `kill_opt' `anything'
	}
end

cap program prockill_plug, plugin using("prockill.plugin")
