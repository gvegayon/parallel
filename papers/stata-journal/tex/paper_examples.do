* net install parallel, from("`c(pwd)'/deliverable/package_files")
** EXAMPLES
* 1) Example Prefix
sysuse auto, clear 
parallel setclusters 2
parallel: gen price2 = price*price

* 2) Example Do-file
//Preliminary
sysuse auto, clear

parallel do make_polynomial.do

* 3) Example Bootstrap
sysuse auto, clear
bs: reg price c.weig##c.weigh foreign rep

parallel bs: reg price c.weig##c.weigh foreign rep

* 4) Example Simulation
//preliminary
cap program drop lnsim

program define lnsim, rclass
  version 14
  syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
  drop _all
  set obs `obs'
  tempvar z
  gen `z' = exp(rnormal(`mu',`sigma'))
  summarize `z'
  return scalar mean = r(mean)
  return scalar Var  = r(Var)         
end 

simulate mean=r(mean) var=r(Var), reps(10000): lnsim, obs(100)

parallel sim, expr(mean=r(mean) var=r(Var)) reps(10000): ///
    lnsim, obs(100)
	
* 5) Example Append
//Preliminary: Build dummy files
mkdir example_append, public
cd example_append
local n_obs 10
forval year=2008/2012{
	forval month=1/12{
		local month_pad : display %02.0f `month'
		mkdir `year'_`month_pad', public
		clear
		set obs `n_obs'
		gen income = runiform(0,1000)
		gen gender="female"
		replace gender="male" if _n<=5
		save `year'_`month_pad'/income.dta, replace
	}
}
cap program drop myprogram

program def myprogram
  gen female = (gender == "female")
  collapse (mean) income, by(female) fast
end

parallel append, do(myprogram) prog(myprogram) ///
	e("%g_%02.0f/income.dta, 2008/2012, 1/12")
	
//Cleanup
forval year=2008/2012{
	forval month=1/12{
		local month_pad : display %02.0f `month'
		rm `year'_`month_pad'/income.dta, replace
		rmdir `year'_`month_pad'
	}
}
cd ..
rmdir example_append

** Example Sequential consistency
set seed 1337 
sysuse auto, clear 
parallel setclusters 2

cap program drop do_work 
program do_work     
  args main_data     
  local num_rep = _N     
  tempname tasks pfile     
  mkmat n seed, matrix(`tasks')     
  qui use "`main_data'", clear     
  tempfile estimates     
  postfile `pfile' long(n seed) float(b_mpg) using "`estimates'"     
  forval i=1/`num_rep'{         
    local seedi = `tasks'[`i',2]         
    set seed `seedi'         
    preserve         
    bsample         
    qui reg price mpg         
    post `pfile' (`=`tasks'[`i',1]') (`seedi') (_b[mpg])         
    restore     
  }     
  postclose `pfile'     
  use "`estimates'", clear 
end

tempfile maindata 
save "`maindata'" 
drop _all 
gen long seed = . 
qui set obs 99 //number of reps
replace seed = int((-1*`c(minlong)'-1)*runiform())
gen long n=_n 
local final_seed = c(seed) 
parallel, program(do_work): do_work "`maindata'" 
mata: rseed(st_local("final_seed"))
sort n

** Benchmarking
* These take a long time and will produce different numbers depending on on the machine
* See the included 20161102_parallel-bechmark_nreps=1000.dta for original output
* If you edit global DATE and nreps and PROGS/TESTS in 01 make sure to edit in 02
do "01_parallel_benchmark.do"
do "02_parallel_benchmark.do"
