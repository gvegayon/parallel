* This script checks that sequential and parallel results are the same.
* it checks -seeding simulate-, -bootstrap-, and -permute-

* TODO:
* - For bootstrap and permute, check that the estimation outputs from -seeding ...- align with main verisons
* - check more of the main options. Low priority (can be added by others as needed).

/*
* In case we're running this individually
include setup_ado.do
*/

parallel setclusters 2
set seed 1337

******** Simulate
cap program drop lnsim
program define lnsim, rclass
	version 15.1
	syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
	drop _all
	qui set obs `obs'
	tempvar z
	gen `z' = exp(rnormal(`mu',`sigma'))
	qui summarize `z'
	return scalar mean = r(mean)
	return scalar Var  = r(Var)
end

forv p = 1/2 {
	set seed 1
	loc par = cond(`p'==2, "parallel parallel_opts(programs(lnsim))", "")
	seeding simulate mean=r(mean) var=r(Var), reps(2) nodots nolegend `par': lnsim, obs(100)
	sort *
	tempfile lnsim`p'
	qui save `lnsim`p'', replace
}
dta_equal `lnsim1' `lnsim2'
*CHECK output here 


************** Bootstrap
*Main version
sysuse auto, clear
set seed 1
bootstrap _b, reps(10) nodots nolegend: regress mpg weight gear foreign

forv p = 1/2 {
	qui sysuse auto, clear
	set seed 1
	loc par = cond(`p'==2, "parallel", "")
	seeding bootstrap _b, reps(10) nodots nolegend `par': regress mpg weight gear foreign
	sort *
	tempfile bs`p'
	qui save `bs`p'', replace
}
dta_equal `bs1' `bs2'
*CHECK output here 


************ Permute
*Main version
qui webuse lbw
set seed 1
seeding permute smoke x2=e(chi2), reps(2) nodots nolegend `par': logit low smoke
	
forv p = 1/2 {
	qui webuse lbw
	set seed 1
	loc par = cond(`p'==2, "parallel", "")
	seeding permute smoke x2=e(chi2), reps(2) nodots nolegend `par': logit low smoke
	sort *
	tempfile perm`p'
	qui save `perm`p'', replace
}
dta_equal `perm1' `perm2'
*CHECK output here 
