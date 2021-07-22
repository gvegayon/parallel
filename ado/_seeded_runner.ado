*! _seeded_runner
*! auth Brian Quistorff
program _seeded_runner
	* Takes a dataset of seeds (maybe directly from -seeding- or via -parallel-), 
	* saves to matrix, reloads the main dataset, sets a global REP counter 
	* (that will get read and incremented by _seeded_cmd_wrapper) and then starts 
	* -simulate- with -_seeded_cmd_wrapper cmd-
	gettoken sub_cmd 0 : 0
	if "`sub_cmd'"=="permute" gettoken permvar 0 : 0
	gettoken 0 cmd : 0, parse(":") bind
	syntax anything(equalok everything), [maindata(string) *]
	gettoken tmp cmd: cmd //pop the ":"
	loc reps = `=_N'
	
	tempname seeds
	*local seeds seeds
	mkmat seeds, matrix(`seeds')
	drop _all
	if "`maindata'"!="" use `maindata', clear
	
	global REP_n 1
	simulate `anything', reps(`reps') `options': _seeded_cmd_wrapper `sub_cmd' `permvar' `seeds' `cmd'
	global REP_n
end
