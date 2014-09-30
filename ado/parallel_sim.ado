*! parallel_sim vers 0.14.6.23 23jun2014
*! auth George G. Vega

program def parallel_sim, eclass
	vers 11.0
	parallel_simulate `0'
	
	/*
	if !replay() { // If it is a replay, 
		parallel_simulate `0'
	}
	else if ("`e(prefix)'" != "bootstrap" | !inlist("`e(pll)'","1") ) { // If the last command runned wasn't nnmatch2
		di as error "Last estimation was not {bf:parallel bs}, was -{bf:`=e(prefix)'}-" 
		exit 301
	}
	else { // if the last command was pll bootstrap, it replays the results
		bs, title(parallel bootstrapping)
	}*/
end

program def parallel_simulate, rclass 
	vers 11.0
	#delimit ;
	syntax anything(name=model equalok everything) [,
		EXPression(string asis) 
		PROGrams(string)
		Mata 
		NOGlobals
		keep  
		Seeds(passthru)
		Randtype(passthru)
		Timeout(integer 60)
		PROCessors(integer 0)
		argopt(string) 
		SAVing(string) Reps(integer -1) *];
	#delimit cr

	/* Checking whereas parallel has been config */	
	if length("$PLL_CLUSTERS") == 0 {
		di "{error:You haven't set the number of clusters}" _n "{error:Please set it with: {cmd:parallel setclusters} {it:#}}"
		exit 198
	}
	
	/* Checking reps */
	if (`reps' < 1) {
			di as err "reps() is required, and must be a positive integer"
			exit 198
	}

		
	/* Setting sizes */
	local csize = floor(`reps'/$PLL_CLUSTERS)
	if (`csize' == 0) error 1
	else {
		local lsize = `csize' + (`reps' - `csize'*$PLL_CLUSTERS)
	}

	/* Reserving a pll_id. This will be stored in the -parallelid- local
	macro */
	mata: parallel_sandbox(5)

	/* Saving the tmpfile */
	local tmpdta = "__pll`parallelid'_sim_dta.dta"
	if (`"`saving'"' == "") {
		if (c(os)=="Windows") local saving = `"`c(tmpdir)'__pll`parallelid'_sim_outdta.dta"'
		else local saving = `"`c(tmpdir)'/__pll`parallelid'_sim_outdta.dta"'
		local save = 0
	}
	else local save = 1
	local simul = `"__pll`parallelid'_sim_simul.do"'
	
	/* Only save if there is data */
	if (c(N)) qui save `tmpdta'
	else di "{result:Warning:}{text: No data loaded.}"
	
	/* Parsing saving */
	_prefix_saving `saving'
	local saving    `"`s(filename)'"'
	if "`double'" == "" {
			local double    `"`s(double)'"'
	}
	local every     `"`s(every)'"'
	local replace   `"`s(replace)'"'
	
	cap confirm file `saving'
	if (!_rc & "`replace'" == "") {
		di "{error:File -`saving'- already exists, use the -replace- option}"
		exit 602
	}
	
	/* Getting the name of the program */
	if (regexm(`"`model'"',"^([a-zA-Z0-9_]+)")) local cmd = regexs(1)
	cap findfile `cmd'.ado
	if (_rc) local programs `programs' `cmd'
	
	/* Creating a tmp program */	
	cap file open fh using `"`simul'"', w replace
	if (c(N)) file write fh `"use `tmpdta', clear"' _n
	file write fh "if (\`pll_instance'==\$PLL_CLUSTERS) local reps = `lsize'" _n
	file write fh "else local reps = `csize'" _n
	file write fh `"local pll_instance : di %04.0f \`pll_instance'"' _n
	file write fh `"simulate `expression', sav(__pll\`pll_id'_sim_eststore\`pll_instance', replace `double' `every') `options' rep(\`reps'): `model' `argopt'"' _n
	file close fh 

	/* Running parallel */
	cap noi parallel do `simul', nodata programs(`programs') `mata' `noglobals' ///
		`randtype' timeout(`timeout') processors(`processors') setparallelid(`parallelid') ///
		 `seeds'
	local seeds = r(pll_seeds)

	if (_rc) {
		if ("`keep'" == "") qui parallel clean, e($LAST_PLL_ID) force
		mata: parallel_sandbox(2, "`parallelid'")
		exit _rc
	}

	if (r(pll_errs)) {
		if ("`keep'" == "") qui parallel clean, e($LAST_PLL_ID) force
		mata: parallel_sandbox(2,"`parallelid'")
		exit 1
	}
	
	/* Appending datasets */
	forval i=1/$PLL_CLUSTERS {
		quietly {
			local pll_instance : di %04.0f `i'
			use `"__pll$LAST_PLL_ID`'_sim_eststore`pll_instance'"', clear
			
			if ((`=`i'-1')) append using `saving'
			save `saving', replace
		}
	}
		
	/* Returning expr data */
	foreach v of varlist _all {
		qui summ `v', meanonly
		return scalar `v' = r(mean)
	}
	return local pll_seeds = "`seeds'"
	return local command = "`model'"
			
	/* Cleaning up */
	if ("`keep'" == "") parallel clean, e($LAST_PLL_ID)
	mata: parallel_sandbox(2, "`parallelid'")
	
	parallel_sim_ereturn
	/*
	/* Getting macros back */
	foreach m of local macros {
		return local `m'  `"``m''"'
	}
	foreach s of local scalars {
		return scalar `s' = ``s''
	}*/
	
end

program def parallel_sim_ereturn, eclass
	vers 11.0
	ereturn local pll 1
end

