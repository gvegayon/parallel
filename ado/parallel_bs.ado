*! parallel_bs vers 0.14.5 12may2014
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
		Saving(string asis) Reps(integer 100) *];
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
	m st_local("simul",parallel_randomid(10, "datetime", 1, 1, 1))
	local tmpdta = "__pll`simul'_bsdta.dta"
	if (`"`saving'"' == "") {
		if (c(os)=="Windows") local saving = `"`c(tmpdir)'__pll`simul'_outdta.dta"'
		else local saving = `"`c(tmpdir)'/__pll`simul'_outdta.dta"'
		local save = 0
	}
	else local save = 1
	local simul = `"__pll`simul'_simul.do"'
	
	qui save `tmpdta'

	/* Creating a tmp program */	
	cap file open fh using `"`simul'"', w replace
	file write fh `"use `tmpdta', clear"' _n
	file write fh "if (\`pll_instance'==\$PLL_CLUSTERS) local reps = `lsize'" _n
	file write fh "else local reps = `csize'" _n
	file write fh `"local pll_instance : di %04.0f \`pll_instance'"' _n
	file write fh `"qui bs `express', sav(__pll\`pll_id'_eststore\`pll_instance', replace) `options' rep(\`reps'): `model' `argopt'"' _n
	file close fh 

	/* Running parallel */
	cap noi parallel do `simul', keep nodata `programs' `mata' `noglobals' `seeds' ///
		`randtype' timeout(`timeout') processors(`processors')
	
	if (_rc) {
		rm `"`simul'"'
		rm `"`tmpdta'"'
		qui parallel clean, e($LAST_PLL_ID) force
		
		exit _rc
	}

	if (r(pll_errs)) {
		rm `"`simul'"'
		rm `"`tmpdta'"'
		qui parallel clean, e($LAST_PLL_ID) force

		exit 1
	}

	preserve
	
	/* Appending datasets */
	forval i=1/$PLL_CLUSTERS {
		quietly {
			local pll_instance : di %04.0f `i'
			use `"__pll$LAST_PLL_ID`'_eststore`pll_instance'"', clear
			
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
	
	/* Cleaning up */
	parallel clean // , e(`pll_id')
	
	restore
	
	rm `"`simul'"'
	rm `"`tmpdta'"'
	
	bstat using `saving', title(parallel bootstrapping)
	
	if (!`save') rm `"`saving'"'
	
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
