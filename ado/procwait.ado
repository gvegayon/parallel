// Succeeds if Process ID has finished (returns ret_code if can get) and fails otherwise.
// Maybe eventually allow waiting for a fixed period of time
//  (but have to be careful to avoid deadlocks, and maybe waiting in Stata is better
//   because you can handle breaks better?)
// Usage:
// cap noi procwait <PID>
// if(!_rc) <something if finished>

program procwait, rclass
	version 11.0
	syntax anything(everything)
	plugin call procwait_plug, `"`anything'"'
	if "`ret_code'"!="" return local ret_code "`ret_code'"
end

program procwait_plug, plugin using("procwait.plugin")
