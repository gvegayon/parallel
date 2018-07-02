//test common wasy that programs might conver to using -parallel-
program test_prog
	tempvar test_var
	gen `test_var' = _n
	tempfile test_dta
	save "`test_dta'", replace
	drop _all
	gen long model_nums =.
	set obs 10
	replace model_nums = _n
	parallel, programs(test_prog.test_worker): test_worker, data("`test_dta'")
end

program test_worker
	syntax, data(string)
	local num_reps = _N
	mkmat model_nums, matrix(madel_nums_mat)
	use "`data'", clear
	tempvar my_new_var
	describe
	mac dir
	forval rep=1/`num_reps' {
		di "`rep'"
	}
end
