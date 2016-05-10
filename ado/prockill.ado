//Kills a process by it's Process ID
program prockill
	version 11.0
	syntax anything(everything)
	
	if (c(os) == "Windows") {
		plugin call prockill_plug, `"`anything'"'
	}
	else{ //sends signal SIGTERM by default
		shell kill `anything'
	}
end

cap program prockill_plug, plugin using("prockill.plugin")
