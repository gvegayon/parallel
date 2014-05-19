*! version 1.14.5.19  19may2014
*! PARALLEL: Stata module for parallel computing
*! by George G. Vega (g.vegayon at gmail)
/*
////////////////////////////////////////////////////////////////////////////////
CHANGE LOG
- Rewrite parallel_finito, parallel_setclusters from stata to mata (speed gains)
- New parallel_run (mata) runs stata in batch mode (speed gains)
version 0.13.05 08may2013
 NEW FEATURES
 - Real random strings generation for pll_id through random.org API
 IMPROVEMENTS
 - reach programs replaced by program_export (more efficient and cleanner)
version 0.13.04 09apr2013
 NEW FEATURES
 - MacOSX support
version 0.12.12 11dec2012
 Thanks to professor Eric Melse who did great contributions on bugs detection
 for this version.
 BUGS
 - "different folder" issue fixed: Now, users should be able to run do files 
   outside the current directory without having any problem
 - "stata path" issue fixed: Adding the "64" ending text to Stata64bit edision
   automatically.
 - "parallel clean" systax issue: Documentation correction
 NEW FEATURES
 - "parallel setstatadir" command: with which you should avoid handling the ado)

version 0.12.10  18oct2012
 - First public version uploaded to SSC
 ////////////////////////////////////////////////////////////////////////////////
*/

// Syntax parser
cap program drop parallel
program def parallel
    version 10.0

	// Checks wether if is parallel prefix or not
	if  (regexm(`"`0'"', "^(do|clean|setclusters|break|version|append|printlog|viewlog)")) { /* If not prefix */
		parallel_`0'
	}
	else if (regexm(`"`0'"', "^bs[,]?[\s ]?")) {              /* Bootstrap */
		local 0 = regexr(`"`0'"', "^bs", "")
		gettoken x 0 : 0, parse(":")
		local 0 = regexr(`"`0'"', "^[:]", "")
		gettoken x options : x, parse(",") bind

		gettoken 0 argopt : 0, parse(",") bind
		parallel_bs `0', argopt(`argopt') `options'
	}
	else if (regexm(`"`0'"',"^([,]?.*[:])")) {               /* if prefix */
		gettoken x 0 : 0, parse(":") 
		local 0 = regexr(`"`0'"', "^[:]", "")
		// Gets the options (if these exists) of parallel
		gettoken x options : x, parse(",") bind
		
		gettoken 0 argopt : 0, parse(",") bind
		parallel_do `0', `options' prefix argopt(`argopt')
	}
	else {
		local val = regexm(`"`0'"', "^([a-zA-Z0-9_]*).*")
		local subcommand = regexs(1) 
		di as result `"-`subcommand'-"' as error " invalid parallel subcommand" as text " ({stata h parallel:{it:help parallel}})"
		exit 198
	}
end

/* Returns the version of parallel */
program def parallel_version, rclass
	di as result "parallel" as text " Stata module for parallel computing"
	di as result "vers" as text " 1.14.5 (9may2014)"
	di as result "auth" as text " George G. Vega (g.vegayon at gmail.com)"
	
	return local pll_vers = "1.14.5"
end

/* Take a look to logfiles */
program def parallel_printlog
	syntax [anything(name=pll_instance)] , [Event(string)] 
	parallel_checklog `pll_instance', e(`event') action(print)
end

program def parallel_viewlog
	syntax [anything(name=pll_instance)] , [Event(string)] 
	parallel_checklog `pll_instance', e(`event') action(view)
end

program def parallel_checklog
	syntax [anything(name=pll_instance)] , [Event(string)] action(string)

	if ("`event'"=="") local event = "$LAST_PLL_ID"
	
	if ("`event'"!=".") {
		/* By default uses 1 */
		if ("`pll_instance'" == "") local pll_instance 1

		local pll_instance : di %04.0f `pll_instance'

		/* Does de file exists */
		local logname = "__pll`event'_do`pll_instance'.log"

		if (c(os) == "Windows") local logname = "`c(tmpdir)'`logname'"
		else local logname = "`c(tmpdir)'/`logname'"

		/* If the logfile does not exists, do nothing*/
		cap confirm file "`logname'"
		if (_rc) {
			di as result "No logfile for instance -`pll_instance'- of parallel process -`event'- found"
			exit
		}

		/* Showing the log in screen */
		if ("`action'"=="print") {
			di as result "{hline 80}"
			di as result %~80s "beginning of file -`logname'-"
			di as result "{hline 80}"
			type `"`logname'"'
			di as result "{hline 80}"
			di as result %~80s "end of file -`logname'-"
			di as result "{hline 80}"
		}
		else view `"`logname'"'
	}
	else {
		di as error "It seems that you haven't use -parallel- yet."
		exit 601
	}

end


////////////////////////////////////////////////////////////////////////////////
// Splits the dataset into clusters
cap program drop parallel_spliter
program def parallel_spliter
	syntax [namelist(name=xtstructure)] [,parallelid(string) sorting(integer 0) force(integer 0) keepusing(varlist)]
	//args xtstructure parallelid Sorting Force
	
	if length("$PLL_CLUSTERS") == 0 {
		di as err "Number of clusters not fixed." as text " Set the number of clusters with " _newline as err "-{cmd:parallel setclusters #}-"
		exit 198
	}
	
	quietly {
		gen _`parallelid'cut = .
		
		if (length("`xtstructure'")) {
		
			/* Checks wheather if the data is in the correct sorting */
			if !`sorting' & !`force' {
				error 5
			}

			/* Checking the data types */
			foreach var of varlist `xtstructure' {
				capture confirm string var `var'
				if (`=_rc') local numvars `numvars' `var'
				else local strvars `strvars' `var'
			}
		}
		
		/* Checking types of data */
		if (length("`numvars'")) local numvars st_data(.,"`numvars'")
		else local numvars J(0,0,.)
		
		if (length("`strvars'")) local strvars st_data(.,"`strvars'")
		else local strvars J(0,0,"")
		
		/* Processing in MATA */
		mata: st_store(., "_`parallelid'cut", parallel_divide_index(`numvars', `strvars'))
				
		if (length("`keepusing'")) {
			keep _`parallelid'cut `keepusing'
			gen __pllnobs`parallelid' = _n
		}
		
		save __pll`parallelid'_dataset, replace
		
		drop _all
	}
	
end

////////////////////////////////////////////////////////////////////////////////
// MAIN PROGRAM
*cap program drop parallel_do
program def parallel_do, rclass
	#delimit ;
	syntax anything(name=dofile equalok everything) 
		[, by(string) 
		Keep 
		KEEPLast 
		prefix 
		Force 
		programs(namelist)
		Mata 
		NOGlobals 
		KEEPTiming 
		Seeds(string)
		NOData 
		Randtype(string)
		Timeout(integer 60)
		PRocessors(integer 0)
		argopt(string)
		KEEPUsing(string)
		SETparallelid(string)
		];
	#delimit cr
	
	if length("$PLL_CLUSTERS") == 0 {
		di "{error:You haven't set the number of clusters}" _n "{error:Please set it with: {cmd:parallel setclusters} {it:#}}"
		exit 198
	}
	
	// Initial checks
	foreach opt in macrolist keep keeplast prefix force mata noglobals keeptiming nodata {
		local `opt' = length("``opt''") > 0
	}

	/* Randtype */
	if ("`randtype'" == "") local randtype = "datetime"
	
	/* If no data parsing has to be done (because of no data!) */
	if (!(c(N)*c(k))) local nodata 1
	
	if (!`keeptiming') {
		timer clear 98
		timer clear 99
	}
	
	timer on 98
	
	// Delets last parallel instance ran
	if (`keeplast' & length("`r(pll_id)'")) cap parallel_clean, e(`r(pll_id)')
	
	// Gets some global values
	local sfn = "$S_FN"
	
	// Gets the directory where to work at
	if (!`prefix') {
	
		/* First checks if the file exists */
		mata: parallel_normalizepath(`"`dofile'"',1)
		local pll_dir = "`filedir'"
		local dofile = "`filename'"
	}
	else local pll_dir = c(pwd)+"/"
		
	
	local initialdir = c(pwd)
	qui cd "`pll_dir'"
	
	if length("`by'") != 0 {
		local sortlist: sortedby
		local sorting = regexm("`sortlist'","^`by'")
	}
	else local sorting = 0
	
	/* Creates a unique ID for the process and secures it */
	if ("`setparallelid'"=="") mata: parallel_sandbox(5)
	else local parallelid = "`setparallelid'"

	global LAST_PLL_ID = "`parallelid'"
	global LAST_PLL_N = $PLL_CLUSTERS
	global LAST_PLL_DIR = "`pll_dir'"		

	/* Generates database clusters */
	if (!`nodata') parallel_spliter `by' , parallelid(`parallelid') sorting(`sorting') force(`force') keepusing(`keepusing')
	
	/* Starts building the files */
	quietly {
	
		/* Saves mata objects */
		if (`mata') {
			mata: mata mlib create l__pll`parallelid'_mlib, replace
			cap mata: mata mlib add l__pll`parallelid'_mlib *()
			cap mata: mata matsave __pll`parallelid'_mata.mmat *, replace			
			if (`=_rc') local matasave = 0
			else local matasave = 1
		}
		else local matasave = 0
	}
	
	/* Writing the dofile */
	mata: st_local("errornum", strofreal(parallel_write_do(strtrim(`"`dofile' `argopt'"'), "`parallelid'", $PLL_CLUSTERS, `prefix', `matasave', !`noglobals', "`seeds'", "`randtype'", `nodata', "`pll_dir'", "`programs'", `processors')))
	
	/* Checking if every thing is ok */
	if (`errornum') {
		qui use __pll`parallelid'_dataset, clear
		
		// Restores original S_FN (file name) value
		global S_FN = "`sfn'"
		
		/* Removing the cut variable */
		qui drop _`parallelid'cut
		
		/* Removes the sandbox file (unprotect the files) */
		mata: parallel_sandbox(2, "`parallelid'")
		
		error `errornum'
	}
	
	timer off 88
	cap timer list
	if (r(t88) == .) local pll_t_setu = 0
	else local pll_t_setu = r(t88)
	
	/* Running the dofiles */
	timer on 99
	mata: st_local("nerrors", strofreal(parallel_run("`parallelid'",$PLL_CLUSTERS,`"$PLL_DIR"',`=`timeout'*1000')))
	timer off 99
	
	/* If parallel finished with an error it restores the dataset */
	if (`nerrors' & !`nodata') {
		qui use __pll`parallelid'_dataset, clear
		global S_FN = "`sfn'"
		cap drop _`parallelid'cut	
	}
	
	cap timer list
	if (r(t99) == .) local pll_t_calc = 0
	else local pll_t_calc = r(t99)
	local pll_t_reps = r(nt99)
	
	timer on 97
	// Paste the databases
	if (!`nodata' & !`nerrors') {
		parallel_fusion `parallelid', clusters($PLL_CLUSTERS) keepusing(`keepusing')
		
		// Restores original S_FN (file name) value
		global S_FN = "`sfn'"
	
		cap drop _`parallelid'cut
	}

	/* Removes the sandbox file (unprotect the files) */
	if ("`setparallelid'" == "") {
		mata: parallel_sandbox(2, "`parallelid'")
		if (!`keep' & !`keeplast') parallel_clean, e("`parallelid'")
	}
	
	timer off 97
	cap timer list
	if (r(t97) == .) local pll_t_fini = 0
	else local pll_t_fini = r(t97)
	
	qui timer list
	return scalar pll_errs = `nerrors'
	return local  pll_dir "`pll_dir'"
	return scalar pll_t_reps = `pll_t_reps'
	return scalar pll_t_setu = `pll_t_setu'
	return scalar pll_t_calc = `pll_t_calc'
	return scalar pll_t_fini = `pll_t_fini'
	return local pll_id = "`parallelid'"
	return scalar pll_n = $PLL_CLUSTERS

	
	qui cd "`initialdir'"
end

////////////////////////////////////////////////////////////////////////////////
// Cleans all files generated by parallel
*cap program drop parallel_clean
program def parallel_clean
	syntax [, Event(string) All Force]
		
	if (length("`event'") != 0 & length("`all'") != 0) {
		di as error `"invalid syntax: Using -pll_id- and -all- jointly is not allowed."'
		exit 198
	}
	
	mata: parallel_clean("`event'", `=length("`all'") > 0', `=length("`force'") > 0')
end

////////////////////////////////////////////////////////////////////////////////
// Sets the number of clusters as a global macro
cap program drop parallel_setclusters
program parallel_setclusters
	syntax anything(name=nclusters)  [, Force Statadir(string asis)]
	
	local nclusters = real(`"`nclusters'"')
	if (`nclusters' == .) {
		di as error `"Not allow: "#" Should be a number"'
		exit 109
	}
	local force = length("`force'")>0
	mata: parallel_setclusters(`nclusters', `force')
	mata: st_local("error", strofreal(parallel_setstatadir(`"`statadir'"', `force')))
	if (`error') di as error `"Can not set Stata directory, try using -statadir()- option"'
	exit `error'
end


////////////////////////////////////////////////////////////////////////////////
// Exports

// Exports a copy of programs
cap program drop program_export
program def program_export
	syntax using/ [,Programlist(string) Inname(string)]
	
	mata: program_export("`using'", "`programlist'", "`inname'")
end


////////////////////////////////////////////////////////////////////////////////
// Appends the clusterized dataset
cap program drop parallel_fusion
program def parallel_fusion
	syntax anything(name=parallelid) , clusters(integer) [keepusing(string)]
	
	capture {
		use "__pll`parallelid'_dta0001.dta", clear
		
		forval i = 2/`clusters' {
			append using `"__pll`parallelid'_dta`=string(`i',"%04.0f")'.dta"'
		}
		
		/* If it just used a set of variables */
		if (length("`keepusing'")) {
			merge 1:1 __pllnobs`parallelid' using __pll`parallelid'_dataset, keep(3) nogen
			drop __pllnobs`parallelid'
		}
	}

	
	
end

////////////////////////////////////////////////////////////////////////////////
// Checks whether the user pressed break inside a loop
cap program drop parallel_break
program def parallel_break
	mata: parallel_break()
end
