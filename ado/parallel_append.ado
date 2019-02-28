*! vers 0.14.6.24 24jun2014
*! auth George G. Vega

program def parallel_append

	vers 11.0

	#delimit ;
	syntax [anything(name=files)] , Do(string asis) [
		in(string asis) 
		if(string asis)
		Expression(string) Keep KEEPLast *];
	#delimit cr
			
	if ("`in'" != "") local in in `in'
	if ("`if'" != "") local if if `if'

	/* Checking arguments */
	if (`"`files'"' == "" & `"`expression'"' == "") {
		di as error "One of -files- or -expr()- must be specified."
		error 198
	}
	else if (`"`anything'"' != "" & `"`expression'"' != "") {
		di as error "-files- and -expr()- cannot be specified at the same time"
		error 198
	}

	/* Expanding the expression */
	if (`"`expression'"' != "") {
		mata: st_local("files",parallel_expand_expr(`"`expression'"'))
	}
	else if (regexm(`"`files'"', "[*]")) local files : dir . files "`files'"
	
	/* Checking cmd/dofile */
	cap confirm file `"`do'"'
	if (_rc) cap confirm file `"`do'.do"'
	if (!_rc) local do = `"`do'.do"'
	else {
		cap `do'
		if (_rc == 199) {
			di as error `"Error: No file or cmd nammed -`do'-"'
			exit 199
		}
	}

	/* Checking out the number of files */
	tokenize `"`files'"'
	local n = 0
	local i = 0
	local nerr = 0
	while ("``++n''" != "") {
		
		/* Checking whether it exists*/
		local fn = `"``n''"'
		if (!regexm(`"`fn'"',"\.dta$")) cap confirm file `"``n''.dta"'
		else cap confirm file `"``n''"'

		if (!_rc) {
			if (!regexm(`"`fn'"',"\.dta$")) local ext = ".dta"
			else local ext = ""
			local file`++i' = "``n''`ext'"
		}
		else {
			di "{result:Warning:}{text:The file -``n''.dta- couldn't be found.}"
		}
	}
	local n = `i'

	/* If no files had been found */
	if (!`n') {
		di as error "No files found"
		error 601
	}

	/* Showing the files that will be used */
	di "{result:The following files will be processed:}"
	forval i=1/`n' {
		di " " as result %03.0f `i' as text " `file`i''"
	}
	
	/* Checking the groups clusters */
	local size = `n'/$PLL_CHILDREN

	local oldnchildren = $PLL_CHILDREN
	local olddir = $PLL_STATA_PATH
	if (`size' < 1) {
		qui parallel initialize `n', statapath(`olddir') f hostnames($PLL_HOSTNAMES) ssh($PLL_SSH)
		local g = 1
		forval i=1/`n' {
			local group`g' `group`g'' `file`i''
		}
	}
	else {
		/* Grouping files */
		local g = 1
		forval i=1/`n' {
			local group`g' `group`g'' `file`i''
			if (!mod(`i',$PLL_CHILDREN)) local ++g
		}
	}
	
	local ng = ceil(`size')
	
	di "{result:The files will be processed in the following order:}"
	forval i=1/`ng' {
		di " " as result %03.0f `i' as text " `group`i''"
	}
	
	/* Getting a common id for the files */
	mata: parallel_sandbox(5)
	local parallelid0 = "`parallelid'"
	local tmpid = "__pll`parallelid'_append"
	mkdir `tmpid'
		
	local nsave = 0
	forval i=1/`ng' {
		
		/* Writing the file */	
		local f `tmpid'.do
		tempname fh
		qui file open `fh' using `f', w replace
		
		tokenize `group`i''
		local j = 0
		local k = 0
		file write `fh' `"cd "`c(pwd)'""' _newline
		while (`"``++j''"' != "") {
			file write `fh' `"if (\`pll_instance' == `++k') {"' _newline
			file write `fh' `"    use ``j'' `if' `in'"' _newline 
			file write `fh' `"    local filename = `"``j''"'"' _newline
			file write `fh' `"    local tmpn = string(`++nsave',"%04.0f")"'_newline _newline "}" _newline
		}
		
		cap findfile `do'
		if (_rc) {
			file write `fh' `"`do'"' _newline
		}
		
		file write `fh' `"gen dta_source = "\`filename'""' _newline
		file write `fh' "compress" _newline
		file write `fh' "save `tmpid'/`tmpid'\`tmpn', replace" _newline
		
		file close `fh'

		qui parallel initialize `--j', s(`olddir') f hostnames($PLL_HOSTNAMES) ssh($PLL_SSH)

		mata: parallel_sandbox(5)
		local parallelid`i' = "`parallelid'"
		cap noi parallel do `f', `options' nodata setparallelid(`parallelid') `keep' `keeplast'

		/* Checking if an error has occurred */
		if (_rc) {
			local orig_rc = _rc
			mata: parallel_sandbox(2, "$LAST_PLL_ID")
			if ("`keep'"=="" & "`keeplast'"=="") qui parallel clean, e(${LAST_PLL_ID}) nologs
			forval j=0/`i' {
				mata: parallel_sandbox(2, "`parallelid`j''")
				if ("`keep'"=="" & "`keeplast'"=="") qui parallel clean, e(`parallelid`j'') nologs
			}
			qui parallel initialize `oldnchildren', s(`olddir') f hostnames($PLL_HOSTNAMES) ssh($PLL_SSH)
			di as error "An error -`=_rc'- has occured while running parallel"
			cap rm `f'
			exit `orig_rc'
		}

		rm `f'
	}

	qui clear
	
	/* Appending all the results */
	forval i=1/`nsave' {
		local tmpn = "`tmpid'"+string(`i',"%04.0f")+".dta"
		cap {
			append using `tmpid'/`tmpn'
			rm `tmpid'/`tmpn'
		}
		
		if (!c(N)) cap use `tmpid'/`tmpn'
		if (_rc) local err `err' `file`i''
	}
	
	/* Labeling */
	quietly {
		if (c(N)) {
			encode dta_source, gen(dta_source2)
			drop dta_source
			ren dta_source2 dta_source 
			lab var dta_source "Original dataset of the observation"
		}
	}
	
	/* Removing the tmp dir and free id */
	forval i = 0/`ng' {
		mata: parallel_sandbox(2, "`parallelid`i''")
		qui parallel clean, e(`parallelid`i'') nologs
	}

	if (`"`err'"'!="") di "{result:Warning:}{text:The following files could't be found}" _newline as text `"`=regexr(`"`err'"',"^[0]","")'"'

	qui parallel initialize `oldnchildren', s(`olddir') f hostnames($PLL_HOSTNAMES) ssh($PLL_SSH)
	
end

