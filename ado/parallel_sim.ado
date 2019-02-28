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
		KEEPTiming
		Keep KEEPLast 
		Seeds(passthru)
		Randtype(passthru)
		Timeout(integer 60)
		PROCessors(integer 0)
		argopt(string) 
		SAVing(string) Reps(integer -1) *];
	#delimit cr

	/* Checking whereas parallel has been config */	
	if length("$PLL_CHILDREN") == 0 {
		di "{error:You haven't set the number of child processes}" _n "{error:Please set it with: {cmd:parallel initialize} {it:#}}"
		exit 198
	}
	
	if ("`keeptiming'" == "") {
		timer clear 97
		timer clear 98
		timer clear 99
	}
	
	timer on 98
	
	/* Checking reps */
	if `reps'<$PLL_CHILDREN {
		_assert `reps'>=1, msg("reps() is required, and must be a positive intege") rc(198)

		local orig_PLL_CHILDREN = ${PLL_CHILDREN}
		global PLL_CLUSTERS = `reps'
		global PLL_CHILDREN = `reps'
		di "Small workload. Temporarily setting number of child processes to ${PLL_CHILDREN}"
	}

		
	/* Setting sizes */
	local csize = floor(`reps'/$PLL_CHILDREN)
	local lsize = `csize' + (`reps' - `csize'*$PLL_CHILDREN)

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
		if "`orig_PLL_CHILDREN'"!="" {
			global PLL_CLUSTERS=`orig_PLL_CHILDREN'
			global PLL_CHILDREN=`orig_PLL_CHILDREN'
		}
		exit 602
	}
	
	/* Getting the name of the program */
	if (regexm(`"`model'"',"^([a-zA-Z0-9_]+)")) local cmd = regexs(1)
	cap findfile `cmd'.ado
	if (_rc) local programs `programs' `cmd'
	
	/* Creating a tmp program */	
	tempname fh
	cap file open `fh' using `"`simul'"', w replace
	if (c(N)) file write `fh' `"use `tmpdta', clear"' _n
	file write `fh' "if (\`pll_instance'==\$PLL_CHILDREN) local reps = `lsize'" _n
	file write `fh' "else local reps = `csize'" _n
	file write `fh' `"local pll_instance : di %04.0f \`pll_instance'"' _n
	file write `fh' `"simulate `expression', sav(__pll\`pll_id'_sim_eststore\`pll_instance', replace `double' `every') `options' rep(\`reps'): `model' `argopt'"' _n
	file close `fh' 

	timer off 98
	cap timer list
	if (r(t98) == .) local pll_t_setu = 0
	else local pll_t_setu = r(t98)

	/* Running parallel */
	cap noi parallel do `simul', nodata programs(`programs') `mata' `noglobals' ///
		`randtype' timeout(`timeout') processors(`processors') setparallelid(`parallelid') ///
		 `seeds' `keep' `keeplast'
	local pllseeds = r(pll_seeds)
	
	local nerrors  = r(pll_errs)
	local pll_dir  = r(pll_dir)
	
	local pll_t_setu = r(pll_t_setu) + `pll_t_setu'
	local pll_t_calc = r(pll_t_calc)
	local pll_t_fini = r(pll_t_fini)
	
	timer on 97

	if (_rc) {
		if ("`keep'"=="" & "`keeplast'"=="") qui parallel clean, e(${LAST_PLL_ID}) force nologs
		mata: parallel_sandbox(2, "`parallelid'")
		if "`orig_PLL_CHILDREN'"!="" {
			global PLL_CLUSTERS=`orig_PLL_CHILDREN'
			global PLL_CHILDREN=`orig_PLL_CHILDREN'
		}
		exit _rc
	}

	if (_rc) {
		if ("`keep'" == "" & "`keeplast'"=="") qui parallel clean, e(${LAST_PLL_ID}) force nologs
		mata: parallel_sandbox(2, "`parallelid'")
		if "`orig_PLL_CHILDREN'"!="" {
			global PLL_CLUSTERS=`orig_PLL_CHILDREN'
			global PLL_CHILDREN=`orig_PLL_CHILDREN'
		}
		exit _rc
	}
	
	/* Appending datasets */
	forval i=1/$PLL_CHILDREN {
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
	if ("`keep'" == "" & "`keeplast'"=="") parallel clean, e(${LAST_PLL_ID}) nologs
	mata: parallel_sandbox(2, "`parallelid'")
	
	timer off 97
	cap timer list
	if (r(t97) == .) local pll_t_fini = 0 + `pll_t_fini'
	else local pll_t_fini = r(t97) + `pll_t_fini'
	
	return scalar pll_errs = `nerrors'
	return local  pll_dir "`pll_dir'"
	// return scalar pll_t_reps = `pll_t_reps'
	return scalar pll_t_setu = `pll_t_setu'
	return scalar pll_t_calc = `pll_t_calc'
	return scalar pll_t_fini = `pll_t_fini'
	return local pll_id = "`parallelid'"
	
	return local pll_seeds = "`pllseeds'"
	
	parallel_sim_ereturn
	if "`orig_PLL_CHILDREN'"!="" {
		global PLL_CLUSTERS=`orig_PLL_CHILDREN'
		global PLL_CHILDREN=`orig_PLL_CHILDREN'
	}
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

