*! Testing prefix syntax
*! version 1.14.6.24 24jun2014
*set trace off
clear all
set more off

vers 11.0

global clusters 1 2 3 4 5 6 7 8

local test1 simulate beta=r(beta), reps(100) : mysim
local test1pll parallel sim, exp(beta=r(beta)) reps(100) : mysim

local test2 simulate beta=r(beta), reps(100) : myoutersim
local test2pll parallel sim, exp(beta=r(beta)) reps(100) prog(myinnersim) : myoutersim

/* Test 1: Simple simulation */
cap program drop mysim
program def mysim, rclass
	// Data generation process (also resampling)
	sysuse auto, clear
	sample 50
	
	summ price
	return scalar beta = r(mean)
end

/* Test 2: Simulation within a simulation */
// Inner simumation: Some estimates
cap program drop myinnersim
program def myinnersim, rclass
	/* Data generation process (in this case, resampling */
	sample 90
	args x
	summ `x'
	return scalar mean = r(mean)
end

// Outer simulation: calls myinnersim
cap program drop myoutersim
program def myoutersim, rclass
	// Data generation process (also resampling)
	sysuse auto, clear
	sample 50
	
	// Sub simulation
	simulate beta=r(mean), reps(10): myinnersim price
	noi summ beta
	return scalar beta = r(mean)
end

foreach c of global clusters {

	parallel setclusters `c', force

	local i = 0
	while (`"`test`++i''"' != "") {
		quietly {
			/* Serial fashion */
			`test`i''
			summ beta	
			local x = r(mean)
			
			/* Parallel fashion */
			noi `test`i'pll'
			summ beta
			local xpll = r(mean)
		}
		di as result "Serial: " %9.2fc `x' " Parallel: " %9.2fc `xpll' ///
			" CLUSTERS: " %2.0fc $PLL_CLUSTERS  `" CMD: `test`i''"' as text
	}
}
