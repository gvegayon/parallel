*! _seeded_runner
*! auth Brian Quistorff
program _seeded_runner
	* Takes a dataset of seeds (maybe directly from -seeding- or via -parallel-), 
	* saves to matrix, reloads the main dataset, sets a global REP counter 
	* (that will get read and incremented by _seeded_cmd_wrapper) and then starts 
	* -simulate- with -_seeded_cmd_wrapper cmd-
	gettoken sub_cmd 0 : 0
	gettoken 0 cmd : 0, parse(":") bind
	gettoken tmp cmd: cmd //pop the ":"
	if "`sub_cmd'"=="permute" gettoken permvar 0 : 0
	syntax anything(equalok everything) [, maindata(string) *]
	loc reps = `=_N'
	
	tempname seeds
	*local seeds seeds
	mkmat seeds, matrix(`seeds')
	drop _all
	if "`maindata'"!="" use `maindata', clear
	
	global REP_n 1
	if "`sub_cmd'"=="sim_to_post" {
		syntax anything(equalok everything) [, maindata(string) nodots]
		
		* parse cmd because we need to add on an option and make sure to not double ,,
		loc 0 `cmd'
		loc orig_anything `anything'
		syntax [anything(equalok everything)] [, *]
		tempname sp_post
		tempfile sp_post_file
		if "`dots'"!="nodots" _dots 0, title(Simulations) reps(`reps')
		postfile `sp_post' `orig_anything' using `sp_post_file'
		forv i=1/`reps' {
			_seeded_cmd_wrapper sim_post `seeds' `anything', `options' postname(`sp_post')
			if "`dots'"!="nodots" _dots `i' 0
		}
		postclose `sp_post'
		use `sp_post_file', clear
	}
	else {
		simulate `anything', reps(`reps') `options': _seeded_cmd_wrapper `sub_cmd' `permvar' `seeds' `cmd'
	}
	global REP_n
end
