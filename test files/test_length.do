do setup_ado.do
program drop _all
macro drop _all
sysuse auto, clear
global nCl = 3
parallel setclusters $nCl, force
set seed 1337

//Test -parallel bs-
if 1{
parallel bs, reps(2): reg price foreign rep
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
parallel bs, reps(`=2*${nCl}'): reg price foreign rep
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
parallel bs, reps(`=2*${nCl}+1'): reg price foreign rep
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
}

//test -parallel sim-
if 1{
cap program drop lnsim
program define lnsim, rclass
	syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
	drop _all
	set obs `obs'
	tempvar z
	gen `z' = exp(rnormal(`mu',`sigma'))
	summarize `z'
	return scalar mean = r(mean)
	return scalar Var  = r(Var)
end

parallel sim, expr(mean=r(mean) var=r(Var)) reps(1): lnsim, obs(100)
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
parallel sim, expr(mean=r(mean) var=r(Var)) reps(${nCl}): lnsim, obs(100)
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
parallel sim, expr(mean=r(mean) var=r(Var)) reps(`=${nCl}+1'): lnsim, obs(100)
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
}

//Test -parallel- (w/o -, by()-)
if 1{
cap program drop simp_bs
program simp_bs
	local reps = _N
	mkmat n seed, matrix(plan)
	forval i=1/`reps'{
		sysuse auto, clear
		bsample
		reg price mpg
		mat b = e(b)
		mat returns = nullmat(returns) \ (plan[`i',1], plan[`i',2], b)
	}
	
	drop _all
	svmat returns
end

cap program drop setup_bs_data
program setup_bs_data
	args nreps
	
	drop _all
	set obs `nreps'
	gen long n=_n
	gen long seed=_n //should be random
end

setup_bs_data 2
parallel, program(simp_bs) : simp_bs
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
setup_bs_data `=${nCl}'
parallel, program(simp_bs) : simp_bs
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
setup_bs_data `=${nCl}+1'
parallel, program(simp_bs) : simp_bs
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
}

//test -parallel, by()-
if 1{ 
sysuse auto, clear
replace foreign=. in 1/20
parallel setclusters 4, force //max is 3
sort foreign
parallel, by(foreign): reg price mpg
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"

gen str1 name = "A"
replace name="B" if mod(_n,3)==0
replace name=""  if foreign==1

parallel setclusters 6, force //max is 5
sort foreign name
parallel, by(foreign name): reg price mpg
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
}

//Test -parallel append-
if 1{
cap program drop test_length_app_program
program test_length_app_program
	gen x = .
end

cap program drop do_app_test
program do_app_test
	args nApp

	sysuse auto, clear
	forval i=1/`nApp' {
		save test_length_app`i'.dta, replace
	}
	parallel append, do(test_length_app_program) prog(test_length_app_program) e("test_length_app%g.dta, 1/`nApp'")
	forval i=1/`nApp' {
		erase test_length_app`i'.dta
	}

end
global LAST_PLL_N =0
do_app_test 2
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
do_app_test `=${nCl}'
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
do_app_test `=${nCl}+1'
di "LAST_PLL_N=$LAST_PLL_N. PLL_CLUSTERS=$PLL_CLUSTERS"
}
