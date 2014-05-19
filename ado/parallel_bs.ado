*! parallel_bs vers 0.14.5.19 19may2014
*! auth George G. Vega

program def parallel_bs, eclass
	if !replay() { // If it is a replay, 
		parallel_bootstrap `0'
	}
	else if ("`e(prefix)'" != "bootstrap" | !inlist("`e(pll)'","1") ) { // If the last command runned wasn't nnmatch2
		di as error "Last estimation was not {bf:parallel bs}, was -{bf:`=e(prefix)'}-" 
		exit 301
	}
	else { // if the last command was pll bootstrap, it replays the results
		bs, title(parallel bootstrapping)
	}
end

program def parallel_bootstrap, rclass 
	#delimit ;
	syntax anything(name=model equalok everything) [,
		EXPress(string asis) 
		programs(passthru)
		Mata 
		NOGlobals 
		Seeds(passthru)
		Randtype(passthru)
		Timeout(integer 60)
		PRocessors(integer 0)
		argopt(string) 
		SAVing(string asis) Reps(integer 100) *];
	#delimit cr

	/* Checking whereas parallel has been config */	
	if length("$PLL_CLUSTERS") == 0 {
		di "{error:You haven't set the number of clusters}" _n "{error:Please set it with: {cmd:parallel setclusters} {it:#}}"
		exit 198
	}
		
	/* Setting sizes */
	local csize = floor(`reps'/$PLL_CLUSTERS)
	if (`csize' == 0) error 1
	else {
		local lsize = `csize' + (`reps' - `csize'*$PLL_CLUSTERS)
	}

	/* Saving the tmpfile */
	mata: parallel_sandbox(5)

	local tmpdta = "__pll`parallelid'_bs_dta.dta"
	if (`"`saving'"' == "") {
		if (c(os)=="Windows") local saving = `"`c(tmpdir)'__pll`parallelid'_bs_outdta.dta"'
		else local saving = `"`c(tmpdir)'/__pll`parallelid'_bs_outdta.dta"'
		local save = 0
	}
	else local save = 1
	local simul = `"__pll`parallelid'_bs_simul.do"'
	
	qui save `tmpdta'

	/* Creating a tmp program */	
	cap file open fh using `"`simul'"', w replace
	file write fh `"use `tmpdta', clear"' _n
	file write fh "if (\`pll_instance'==\$PLL_CLUSTERS) local reps = `lsize'" _n
	file write fh "else local reps = `csize'" _n
	file write fh `"local pll_instance : di %04.0f \`pll_instance'"' _n
	file write fh `"bs `express', sav(__pll\`pll_id'_bs_eststore\`pll_instance', replace) `options' rep(\`reps'): `model' `argopt'"' _n
	file close fh 

	/* Running parallel */
	cap noi parallel do `simul', nodata `programs' `mata' `noglobals' `seeds' ///
		`randtype' timeout(`timeout') processors(`processors') setparallelid(`parallelid')

	if (_rc) {
		qui parallel clean, e($LAST_PLL_ID) force
		mata: parallel_sandbox(2, "`parallelid'")
		exit _rc
	}

	if (r(pll_errs)) {
		qui parallel clean, e($LAST_PLL_ID) force
		mata: parallel_sandbox(2,"`parallelid'")
		exit 1
	}

	preserve
	
	/* Appending datasets */
	forval i=1/$PLL_CLUSTERS {
		quietly {
			local pll_instance : di %04.0f `i'
			use `"__pll$LAST_PLL_ID`'_bs_eststore`pll_instance'"', clear
			
			if ((`=`i'-1')) append using `saving'
			save `saving', replace
		}
	}
	
	/* Storing macros */
	local macros : r(macros)
	local scalars : r(scalars)
	foreach m of local macros {
		local `m' = r(`m')
	}
	foreach s of local scalars {
		local `s' = r(`s')
	}
		
	restore
	
	/* Returning bs data */
	bstat using `saving', title(parallel bootstrapping)
	
	/* Cleaning up */
	parallel clean, e($LAST_PLL_ID)
	mata: parallel_sandbox(2, "`parallelid'")
	
	parallel_bs_ereturn
	
	/* Getting macros back */
	foreach m of local macros {
		return local `m'  `"``m''"'
	}
	foreach s of local scalars {
		return scalar `s' = ``s''
	}
	
end

program def parallel_bs_ereturn, eclass
	ereturn local pll 1
end
