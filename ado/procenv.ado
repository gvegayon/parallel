//Used to get or set environment variables
// (Note: -local eval: environment ename- won't report updated environment variable values, but this will)
// Setting useful for setting things up for spawned processes (as they inherit env), in which case return to normal after spawn
//  (when the process is Stata this is especially useful as you can set STATATMP which can't be set in the program).

// Usage:
// display list all
//   procenv get 
// get value from r(env_value)
//   procenv get STATATMP
// set value
//   procenv set STATATMP=C:/Users/John Doe/Temp 
program procenv, rclass
	version 11.0
	syntax anything(equalok everything)
	gettoken func anything : anything
	local anything = strtrim(`"`anything'"') //get rid of initial space
	plugin call procenv_plug, `"`func'"' `"`anything'"'
	return local value `"`env_value'"'
end

cap program procenv_plug, plugin using("procenv.plugin")
