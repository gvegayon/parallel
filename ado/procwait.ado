// Succeeds if Process ID has finished (returns ret_code if can get) and fails otherwise.
// Maybe eventually allow waiting for a fixed period of time
//  (but have to be careful to avoid deadlocks, and maybe waiting in Stata is better
//   because you can handle breaks better?)
/* Usage:
cap noi procwait <PID>
//cap noi procwait <PID>, connection(ssh node2)
if(!_rc) <something if finished>
*/
program procwait, rclass
	version 11.0
	syntax anything(everything) [, connection(string)]
	
	if (c(os) == "Windows") {
		plugin call procwait_plug, `"`anything'"'
		if "`ret_code'"!="" return local ret_code "`ret_code'"
	}
	else {
		//kill -0 is the POSIX way of checking
		tempfile kill_exit_code
		shell `connection' kill -0 `anything' 2> /dev/null; echo \$? > "`kill_exit_code'"
		//kill exits with 0 if exists, 1 otherwise
		
		tempname fh
		file open `fh' using `"`kill_exit_code'"', read text
		file read `fh' not_active
		file close `fh'
		
		if !`not_active' error 1
	}
end

cap program procwait_plug, plugin using("procwait.plugin")
