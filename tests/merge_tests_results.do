clear all
set more off
set trace off

log using all_tests_results.txt, text replace

/* Building name of test */
local tsts : dir "." files "test*.log" 

set more off
foreach t of local tsts {
	di as result "{hline}"
	di as result "{hline}"
	di as result "{hline}"
	di %~80s "file `t'"
	di as result "{hline}"
	di as result "{hline}"
	di as result "{hline}"
	type `t'
	di "{hline}" as text
}

cap log close
