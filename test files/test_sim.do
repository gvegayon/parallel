clear all
set more off
*set trace off

set obs 100
set seed 54321
gen x = rnormal()
gen true_y = 1+2*x
save truth, replace

cap program drop hetero1
program hetero1
	version 11.0
	args c
	use truth, clear
	gen y = true_y + (rnormal() + `c'*x)
	regress y x
end

timer clear
timer on 1
simulate _b _se, reps(5000) sav(truth_sim, replace): hetero1 3
timer off 1

use truth, clear

timer on 2
parallel setclusters 2, force hostnames(`: env PLL_TEST_NODES')
parallel sim, keepl expr(_b _se) reps(5000) sav(truth_sim_pll, replace): hetero1 3
return list
timer off 2

timer list	

erase truth.dta
erase truth_sim.dta
erase truth_sim_pll.dta
