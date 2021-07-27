*! seeding: Allow reproducible results for -simulate-, -bootstrap-, -permute-
*!   across both sequential and parallel runs.
*!   Also allows a modified loop that saves results via -post-
*!   Provides loops with both $REP_gl_i and $REP_lc_i
*! Ex usage:
*!   seeding simulate [exp_list] , reps(#) [options] : command
*!   seeding bootstrap exp_list [, options eform_option] : command
*!   seeding permute permvar exp_list [, options] : command
*! auth Brian Quistorff
program seeding
	* Saves data and makes the main dataset the seeds.
	* Either calls _seeded_runner directly or has parallel call _seeded_runner
	* Parallel will split up the dataset (seeds) across the workers.
	gettoken sub_cmd 0 : 0
	gettoken 0 cmd : 0, parse(":") bind
	gettoken tmp cmd: cmd //pop the ":"
	syntax anything(equalok everything), [reps(integer 100) parallel parallel_opts(string) *]
	
	if `=_N'>0 {
		tempfile maindata
		qui save "`maindata'"
	}
	if("`sub_cmd'"=="permute"){
		`cmd'
		*Parse expression list and save values (attach to variable char later)
		gettoken permvar exp_list : anything
		loc exp_list = strtrim("`exp_list'")
		loc exp_list_len : word count "`exp_list'"
		forv w_i=1/`exp_list_len' {
			loc token : word `w_i' of "`exp_list'"
			gettoken l`w_i' tmp : token, parse("=")
			gettoken tmp r`w_i': tmp, parse("=") //pop the =
			loc r`w_i'_val = `r`w_i'' 			
		}
	}
	drop _all
	gen long seeds = .
	global REP_N `reps'
	qui set obs `reps'
	qui replace seeds = runiformint(0, `c(maxlong)') //technically this misses a few possibilities at the upper end of long (because of missings)
	local final_seed = c(seed)
	
	if "`parallel'"=="parallel" loc parallel_prefix "parallel, `parallel_opts':"
	`parallel_prefix' _seeded_runner `sub_cmd' `anything', maindata(`maindata') `options': `cmd'

	global REP_N
	*For some commands run procedures on the results.
	if("`sub_cmd'"=="permute") {
		char _dta[permvar] `permvar'
		forv w_i=1/`exp_list_len' {
			char `l`w_i''[permute] `r`w_i'_val'			
		}
		permute
		use "`maindata'", clear
	}
	if("`sub_cmd'"=="bootstrap") {
		tempfile resample_results
		save "`resample_results'"
		use "`maindata'", clear
		`cmd'
		tempname b
		matrix `b' = e(b)
		bstat using "`resample_results'", stat(`b')
	}
	mata: rseed(st_local("final_seed")) //-set seed `final_seed'- makes a mess on the screen with strL RNG states
end




