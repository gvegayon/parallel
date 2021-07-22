*! seeding: Allow reproducible results for -simulate-, -bootstrap-, -permute-
*!   across both sequential and parallel runs.
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
	syntax anything(equalok everything), [reps(integer 100) parallel parallel_opts(string) *]
	gettoken tmp cmd: cmd //pop the ":"
	
	if `=_N'>0 {
		tempfile maindata
		qui save "`maindata'"
	}
	drop _all
	gen long seeds = .
	qui set obs `reps'
	qui replace seeds = runiformint(0, `c(maxlong)') //technically this misses a few possibilities at the upper end of long (because of missings)
	local final_seed = c(seed)
	
	if "`parallel'"=="parallel" loc parallel_prefix "parallel, `parallel_opts':"
	`parallel_prefix' _seeded_runner `sub_cmd' `anything', maindata(`maindata') `options': `cmd'

	*For some commands run procedures on the results.
	if("`sub_cmd'"=="permute") {
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




