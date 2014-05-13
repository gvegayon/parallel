*! vers 0.14.5 9may2014
*! auth George G. Vega

program def parallel_append

	vers 11.0

	syntax [anything(name=files)] , Do(string asis)[ in(string asis) if (string asis) Expression(string) *]
			
	if ("`in'" != "") local in in `in'
	if ("`if'" != "") local if if `if'

	/* Checking arguments */
	if (`"`anything'"' == "" & `"`expression'"' == "") {
		di as error "One of -files- or -expr()- must be specified."
		error 1
	}
	else if (`"`anything'"' != "" & `"`expression'"' != "") {
		di as error "-files- and -expr()- cannot be specified at the same time"
		error 1
	}

	/* Expanding the expression */
	if (`"`expression'"' != "") {
		mata: st_local("files",parallel_expand_expr(`"`expression'"'))
	}

	/* Checking out the number of files */
	tokenize `files'
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
			di as result "{it:Warning:}{text:The file -``n''.dta- couldn't be found.}"
		}
	}
	local n = `i'

	/* If no files had been found */
	if (!`n') {
		di as error "No files found"
		error 1
	}

	/* Showing the files that will be used */
	di "{result:The following files will be processed:}"
	forval i=1/`n' {
		di as text %03.0f "`i'" as result " `file`i''"
	}
	
	/* Checking the groups clusters */
	local size = `n'/$PLL_CLUSTERS

	local oldclusters = $PLL_CLUSTERS
	local olddir = $PLL_DIR
	if (`size' < 1) {
		qui parallel setclusters `n', statadir(`olddir') f
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
			if (!mod(`i',$PLL_CLUSTERS)) local ++g
		}
	}
	
	local ng = ceil(`size')
	
	forval i=1/`ng' {
		di "{result:The files will be processed in the following order:}"
		di as text " Group " %02.0f "`i':" as result "`group`i''"
	}
	
	/* Getting a common id for the files */
	local err = 1
	while (`err') {
		mata: (void) parallel_randomid(10,"",1,1,1)
		local tmpid = "__pllappend`r(id1)'"
		cap mkdir `tmpid'	
		local err = _rc
	}
	
	local nsave = 0
	forval i=1/`ng' {
		
		/* Writing the file */	
		local f `tmpid'.do
		qui file open fh using `f', w replace
		
		tokenize `group`i''
		local j = 0
		local k = 0
		file write fh "cd `c(pwd)'" _newline
		while (`"``++j''"' != "") {
			file write fh "if (\`pll_instance' == `++k') {" _newline
			file write fh "    use ``j'' `if' `in'" _newline 
			file write fh `"    local tmpn = string(`++nsave',"%04.0f")"' _newline "}" _newline
		}
		
		cap findfile `do'
		if (_rc) {
			file write fh `"`do'"' _newline
		}
		
		file write fh "compress" _newline
		file write fh "save `tmpid'/`tmpid'\`tmpn', replace" _newline
		
		file close fh

		qui parallel setclusters `--j', s(`olddir') f
		parallel do `f', `options'

		/*!less __pll`=r(pll_id)'_do1.do
		!less __pll`=r(pll_id)'_do1.log*/
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
	
	/* Removing the tmp dir */
	cap rmdir `tmpid'

	if (length("`err'")) di as result "{it:Warning:The following files could't be found}" _newline as text "`err'"

	qui parallel setclusters `oldclusters', s(`olddir') f
	
end

