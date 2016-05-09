//Kills a process by it's Process ID
program prockill
	version 11.0
	syntax anything(everything)
	plugin call prockill_plug, `"`anything'"'
end

program prockill_plug, plugin using("prockill.plugin")
