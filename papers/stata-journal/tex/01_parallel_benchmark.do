/*
Benchmark program

This dofile describes a program that can be used to generate make benchmark
comparisons between the parallel and serial fashion of a routine.

This is work-in-progress.
*/ 

clear all
set more off
set trace off
parallel clean, all force
// set matsize 1000

cap program drop parallel_benchmark
program def parallel_benchmark
	version 12.1
	syntax anything [, Mat(name) Times(integer 1) Wait(integer 500) inpll *]
	
	/* Creating the empty matrix */
	tempname plltimes
	mata: `plltimes' =  J(3,`times',.)
	
	forval i=1/`times' {
		/* Preserving */
		preserve
		
		/* Parallel computation ----------------------------------------------*/
		if ("`options'" == "") local opt ""
		else local opt , `options'
		
		if ("`inpll'" == "") parallel `opt': `anything'
		else {
			global INPLL 1
			`anything'
			global INPLL 0
		}
		
		/* Saving results */
		mata: `plltimes'[1::2,`i'] = `=r(pll_t_calc)'\ `=r(pll_t_calc) + r(pll_t_setu) + r(pll_t_fini)'
		
		/* Serial computation ------------------------------------------------*/
		
		timer clear 99
		timer on 99 
		`anything'
		timer off 99
		
		/* Saving results */
		cap timer list
		//mat def plltimes = plltimes, (curtimes\r(t99))
		mata: `plltimes'[3,`i'] = `=r(t99)'
		
		/* Restoring and returning -------------------------------------------*/
		restore
		
		if (~mod(`i',10)) {
			display "{dup 80:*}" _newline "*"  _newline "* Simulation " ///
				%04.0f `i' "/" %04.0f `times' _newline "*" ///
				 _newline "{dup 80:*}"
		}
		
		
	}

	qui {
		drop _all
		set obs `times'
		gen comp_pll   = .
		gen tot_pll    = .
		gen tot_serial = .
		
		mata: st_store(.,., `plltimes'')
	}
		
end

/*******************************************************************************
*
* DEFINITION OF ROUTINES TO TEST
*
*******************************************************************************/

/* Bootstrap */
prog def BOOTTEST
	// Loading data for boot
	quietly {
		sysuse auto, clear
		expand 10
	}
	if ($INPLL == 1) {
		parallel bs, rep($size) nodots: regress mpg weight gear foreign
	}
	else if ($INPLL == 0) {
		bs, rep($size) nodots: regress mpg weight gear foreign
	} 
	else {
		error 1
	}
end

/* Monte carlo Simulation */
prog def mysim, rclass
	drop _all
	set obs 1000
	
	gen eps = rnormal()
	gen X   = rnormal()
	gen Y   = X*2 + eps
	
	reg Y X
	
	mat def ans = e(b)
	return scalar beta = ans[1,1]
end


prog def SIMTEST

	if ($INPLL == 1) {
		parallel sim, reps($size) expr(beta=r(beta)) nodots: mysim
	}
	else if ($INPLL == 0) {
		simulate beta=r(beta), reps($size) nodots: mysim
	}
	else {
		error 1
	}
end

/* Reshape */


/*******************************************************************************
*
* RUNNING TESTS
*
*******************************************************************************/

/* OVERALL PARAMETERS */
global nreps  1000
global CLUSTS 2 4
global SIZES  1000 2000 4000
global PROGS  SIMTEST BOOTTEST
global DATE   20161102
global OVERWRITE 1
global SYSVARS os born_date flavor stata_version machine_type current_date ///
	current_time processors

m: st_global("filename", sprintf("%f_parallel-bechmark_nreps=%04.0f.dta",$DATE, $nreps))

// Counter for writing the file
foreach PROG of global PROGS {
	foreach CLUST of global CLUSTS {
		foreach SIZE of global SIZES {
			// Cleaning space
			parallel setclusters `CLUST'
			parallel clean, all force
			global size = `SIZE'
			
			// Running the program: This will generate a dataset with
			// info about the computing times
			parallel_benchmark `PROG', t($nreps) prog(`PROG') inpll
			
			// Adding additional information: Problem and pll vers
			parallel version
			gen pll_version  = r(pll_vers)
			gen test         = "`PROG'"
			gen problem_size = `SIZE'
			gen nclusters    = `CLUST'
			gen nreps        = $nreps
			
			// More info: System variables
			foreach var of global SYSVARS {
				cap gen `var' = c(`var')
			}
			
			// Checking whether the file exists or not
			if ($OVERWRITE) {
				cap file rm "$filename"
				global OVERWRITE 0
			}
			else {
				cap append using "$filename"
			}
			
			save "$filename", replace
			
			// Sleeping a bit				 
			sleep 1000
		}
		
	}
	di 
}


