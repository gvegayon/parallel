*! version 1.18.2 20mar2017
*! PARALLEL: Stata module for parallel computing
*! by George G. Vega [cre,aut], Brian Quistorff [ctb]
*! 
*! Project website: 
*!   https://github.com/gvegayon/parallel
*! Bug reports:
*!   https://github.com/gvegayon/parallel/issues
/*
Copyright (c) 2014  <George G. Vega>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Syntax parser
program def parallel
    version 11.0

	// Checks wether if is parallel prefix or not
	if  (regexm(`"`0'"', "^(do|clean|setclusters|break|version|append|printlog|viewlog|numprocessors)")) {
	/* If not prefix */
		parallel_`0'
	} 
	else if (regexm(`"`0'"', "^(bs|sim)[,]?[\s ]?")) {
	/* Prefix bootstrap or simulate */
		local cmd = regexs(1)
		mata: st_local("0", regexr(st_local("0"), "^(bs|sim)", ""))
		gettoken x 0 : 0, parse(":") bind
		local 0 = regexr(`"`0'"', "^[:]", "")
		gettoken x options : x, parse(",") bind

		gettoken 0 argopt : 0, parse(",") bind
		parallel_`cmd' `0', argopt(`argopt') `options'
	} 
	else if (regexm(`"`0'"',"^([,]?.*[:])")) {              
	/* if prefix */
		gettoken x 0 : 0, parse(":") bind 
		mata: st_local("0", regexr(st_local("0"), "^[:]", ""))
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

/*
 For Windows we use an environment variable that could be redefined by a parent 
   (both a plus and minus). Alternative is to sum output from command:
    WMIC CPU Get DeviceID,NumberOfCores,NumberOfLogicalProcessors
	
 For *nix see http://stackoverflow.com/questions/6481005/ for alternatives.
   Note: 'nproc --all' does not return the right result on some cloud providers where systems are shared.
*/
program parallel_numprocessors, rclass
	if "`c(os)'"=="Windows" {
		local nproc : env NUMBER_OF_PROCESSORS
	}
	else {
		tempfile nproc_out
		! getconf _NPROCESSORS_ONLN > "`nproc_out'"
		tempname nproc_out_fhandle
		file open `nproc_out_fhandle' using "`nproc_out'", read text
		file read `nproc_out_fhandle' nproc
		local r_eof = `r(eof)'
		file close `nproc_out_fhandle'
		_assert `r_eof'==0, msg("Wasn't able to read output from system")
	}
	
	local nproc = int(real("`nproc'"))
	_assert "`nproc'"!=".", msg("Wasn't able to interpret output from system")
	
	di "Number of logical processors: `nproc'"
	return scalar numprocessors = `nproc'
end

/* Returns the version of parallel */
program def parallel_version, rclass
	version 11.0
	di as result "parallel" as text " Stata module for parallel computing"
	di as result "vers" as text " 1.18.2 20mar2017"
	di as result "auth" as text " George G. Vega [cre,aut], Brian Quistorff [ctb]"
	
	return local pll_vers = "1.18.2"
end

/* Take a look to logfiles */
program def parallel_printlog
	version 11.0
	syntax [anything(name=pll_instance)] , [Event(string)] 
	parallel_checklog `pll_instance', e(`event') action(print)
end

program def parallel_viewlog
	version 11.0
	syntax [anything(name=pll_instance)] , [Event(string)] 
	parallel_checklog `pll_instance', e(`event') action(view)
end

program def parallel_checklog
	version 11.0
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
program def parallel_spliter
	version 11.0
	syntax [namelist(name=xtstructure)] [,parallelid(string) sorting(integer 0) force(integer 0) keepusing(varlist) orig_cl_local(string)]
	//args xtstructure parallelid Sorting Force
	
	if length("$PLL_CLUSTERS") == 0 {
		di as err "Number of clusters not fixed." as text " Set the number of clusters with " _newline as err "-{cmd:parallel setclusters #}-"
		exit 198
	}
	
	//quietly {
		if (length("`xtstructure'")) {
			_assert `sorting' | `force', msg("Data not sorted") rc(5)

			/* Checking the data types */
			foreach var of varlist `xtstructure' {
				capture confirm string var `var'
				if (`=_rc') local numvars `numvars' `var'
				else local strvars `strvars' `var'
			}
			
			/* calculate max possible clusters */
			egen _`parallelid'grp = group(`xtstructure'), missing
			summ _`parallelid'grp, meanonly
			local max_n_cl = `r(max)'
		}
		else {
			local max_n_cl = _N
		}
		
		/* Do we have too many clusters? */
		if (`max_n_cl'<$PLL_CLUSTERS){
			c_local `orig_cl_local' ${PLL_CLUSTERS}
			global PLL_CLUSTERS = `max_n_cl'
			di "Small workload/num groups. Temporarily setting number of clusters to ${PLL_CLUSTERS}"
		}
		
		if (length("`xtstructure'")) {
			preserve
			keep _`parallelid'grp
			contract _`parallelid'grp
			sort _freq
			//Figuring out the mapping from groupID to cut that equalizes sizes is the "Partition Problem"
			//which is hard to solve exactly (it's NP-complete). A rough solution suffices here though.
			gen _`parallelid'cut = mod(_n, ${PLL_CLUSTERS}) + 1
			tempfile grp_to_cut_map
			qui save `"`grp_to_cut_map'"'
			restore
			
			qui merge m:1 _`parallelid'grp using `"`grp_to_cut_map'"', keepusing(_`parallelid'cut) nogenerate
			drop _`parallelid'grp
			sort `xtstructure'
		}
		else {
			gen _`parallelid'cut = ceil(_n*${PLL_CLUSTERS}/_N) //each of size _N/$PLL_CLUSTERS
		}
			
		if (length("`keepusing'")) {
			keep _`parallelid'cut `keepusing'
			gen __pllnobs`parallelid' = _n
		}
		
		qui save __pll`parallelid'_dataset, replace
		drop _all
	//}
	
end

//in a subprogram because some of the outputopts may have the same name as -parallel- options
program pll_remove_replace
	syntax, pll_argopt(string) pll_outputopts(string)
	
	//parse the original options
	foreach pll_outputopt of local pll_outputopts{
		local pll_outputopts_syn "`pll_outputopts_syn' `pll_outputopt'(string)"
	}
	local 0 : copy local pll_argopt
	syntax [anything(equalok everything)][, `pll_outputopts_syn' *]
	
	//remove the ones were are subbing out
	c_local argopt `"`anything', `options'"'
	
	//some may be null so only sub out real ones
	foreach pll_outputopt of local pll_outputopts{
		if "`pll_outputopt'"!="" local outputopts "`outputopts' `pll_outputopt'"
	}
	c_local outputopts `outputopts'
	/* old method (doesn't account for syntax eliding blank ones
	//make version of argopt that doesn't have the options that will be swapped out
	local argopt_orig : copy local argopt
	foreach outputopt of local outputopts{
		local argopt = regexr(`"`argopt'"',"`outputopt'\([^\)]*\)","")
	}*/
end

//allow some or all files to not have been created
//If at least one file was made, even if it was empty, make a file
// (same save dynamics as user program)
program pll_collect
	syntax, folder(string) parallelid(string) outputopts(string) argopt_orig(string)
	preserve
	
	foreach outputopt of local outputopts{
		mata: st_local("val", strofreal(regexm(st_local("argopt_orig"),st_local("outputopt")+"\(([^)]+)\)")))
		if `val'{
			mata: st_local("outfile", regexs(1))
			//get rid of quotes
			local outfile `outfile'
			local emptyok ""
			drop _all
			forval i=1/$PLL_CLUSTERS{
				cap append using `"`folder'__pll`parallelid'_out_`outputopt'`=strofreal(`i',"%04.0f")'"'
				if (_rc==0) local emptyok "emptyok"
			}

			qui save `"`outfile'"', replace `emptyok'
		}
	}
end

////////////////////////////////////////////////////////////////////////////////
// MAIN PROGRAM
// There are things we need to possibly restore on exit
// - Data/S_FN (this is taken care of by -preserve-)
// - PWD (non-indented capture block)
// - Temporaliy changed number of clusters (non-indented capture block)
// - Turn off the timer (do within catch for capture blocks)
program def parallel_do, rclass
	version 11.0

	#delimit ;
	syntax anything(name=dofile equalok everything) 
		[, by(string) 
		Keep 
		KEEPLast 
		prefix 
		Force 
		PROGrams(string)
		Mata 
		NOGlobals 
		KEEPTiming 
		Seeds(string)
		NOData 
		Randtype(string)
		Timeout(integer 60)
		PROCessors(integer 0)
		argopt(string)
		KEEPUsing(string)
		SETparallelid(string)
		OUTputopts(string)
		DETerministicoutput
		];
	#delimit cr
	
	if length("$PLL_CLUSTERS") == 0 {
		di as err "You haven't set the number of clusters" _n "Please set it with: {cmd:parallel setclusters} {it:#}"
		exit 198
	}
	
	if `c(noisily)'==0 & "`programs'"!="" {
		di as err "If you want to pass programs in memory (using the option programs)" _n "then the program must be run noisily."
		exit 198
	}
	
	// Initial checks
	foreach opt in macrolist keep keeplast prefix force mata noglobals keeptiming nodata deterministicoutput {
		local `opt' = length("``opt''") > 0
	}

	/* Randtype */
	if ("`randtype'" == "") local randtype = "datetime"
	
	/* If no data parsing has to be done (because of no data!) */
	if (!(c(N)*c(k))) local nodata 1
	
	if (!`keeptiming') {
		timer clear 97
		timer clear 98
		timer clear 99
	}
	
	timer on 98
	
	// Deletes last parallel instance ran
	local last_id = cond("`r(pll_id)'"!="","`r(pll_id)'", "$LAST_PLL_ID")
	if (`keeplast' & length("`last_id'")) cap parallel_clean, e(`last_id') nologs
	
	if length("`by'") != 0 {
		local sortlist: sortedby
		local sorting = regexm("`sortlist'","^`by'")
	}
	else local sorting = 0
	
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
	capture noisily { //Start capture block for PWD & $PLL_CLUSTERS
	
	/* Creates a unique ID for the process and secures it */
	if ("`setparallelid'"=="") mata: parallel_sandbox(5)
	else local parallelid = "`setparallelid'"

	/* Generates database clusters */
	if (!`nodata'){
		local sfn = "$S_FN" // be able to "fake" restore this
		preserve
		
		parallel_spliter `by' , parallelid(`parallelid') sorting(`sorting') force(`force') keepusing(`keepusing') orig_cl_local(orig_PLL_CLUSTERS)
	}

	global LAST_PLL_ID = "`parallelid'"
	global LAST_PLL_DIR = "`pll_dir'"	
	global LAST_PLL_N = $PLL_CLUSTERS	
	
	/* Starts building the files */
	local work_around_no_cwd = 0
	quietly {
	
		/* Saves mata objects */
		if (`mata') {
			mata: mata mlib create l__pll`parallelid'_mlib, replace
			cap mata: mata mlib add l__pll`parallelid'_mlib *()
			cap which l__pll`parallelid'_mlib.mlib
			if _rc!=0{
				local work_around_no_cwd = 1
				noi di "Note: In order to pass mata objects to the clusters, they are saved to a temporary mlib file in the current directly."
				noi di "      Your ado-path doesn't contain the current directory."
				noi di "      We have added the current directory to the end of the ado-path for the clusters.."
			}
			cap mata: mata matsave __pll`parallelid'_mata.mmat *, replace			
			if (`=_rc') local matasave = 0
			else local matasave = 1
		}
		else local matasave = 0
	}
	
	//see if we handle extra output streams
	if "`outputopts'"!=""{
		local argopt_orig : copy local argopt
		pll_remove_replace, pll_argopt(`"`argopt'"') pll_outputopts(`outputopts')
	}
	
	/* Writing the dofile */
	mata: st_local("errornum", strofreal(parallel_write_do(strtrim(`"`dofile' `argopt'"'), "`parallelid'", $PLL_CLUSTERS, `prefix', `matasave', !`noglobals', "`seeds'", "`randtype'", `nodata', "`pll_dir'", "`programs'", `processors',`work_around_no_cwd',"`outputopts'")))
	if (`errornum') {
		/* Removes the sandbox file (unprotect the files) */
		mata: parallel_sandbox(2, "`parallelid'") 
		
		error `errornum'
	}
	
	timer off 98
	cap timer list
	if (r(t98) == .) local pll_t_setu = 0
	else local pll_t_setu = r(t98)
	
	/* Running the dofiles */
	timer on 99
	mata: st_local("nerrors", strofreal(parallel_run("`parallelid'",$PLL_CLUSTERS,`"$PLL_STATA_PATH"',`=`timeout'*1000', `deterministicoutput')))
	timer off 99
	
	cap timer list
	if (r(t99) == .) local pll_t_calc = 0
	else local pll_t_calc = r(t99)
	local pll_t_reps = r(nt99)
	
	timer on 97
	
	if ("`outputopts'"!=""  & !`nerrors'){
		pll_collect, folder("`pll_dir'") parallelid("`parallelid'") outputopts(`outputopts') argopt_orig(`"`argopt_orig'"')
	}
	
	// Paste the databases
	if (!`nodata' & !`nerrors') {
		parallel_fusion `parallelid', clusters($PLL_CLUSTERS) keepusing(`keepusing')
		cap drop _`parallelid'cut
		
		global S_FN = "`sfn'" // Restores original S_FN (file name) value
		restore, not
	}
	
	return scalar pll_n = $PLL_CLUSTERS
	
	/* Removes the sandbox file (unprotect the files) */
	if ("`setparallelid'" == "") {
		mata: parallel_sandbox(2, "`parallelid'")
		if (!`keep' & !`keeplast') parallel_clean, e("`parallelid'") nologs
	}
	
	} //End capture block
	if _rc {
		local orig_rc = _rc
		qui cd "`initialdir'"
		if "`orig_PLL_CLUSTERS'"!="" global PLL_CLUSTERS=`orig_PLL_CLUSTERS'
		cap timer off 97
		cap timer off 98
		cap timer off 99
		exit `orig_rc'
	}
	qui cd "`initialdir'"
	if "`orig_PLL_CLUSTERS'"!="" global PLL_CLUSTERS=`orig_PLL_CLUSTERS'
	
	timer off 97
	cap timer list
	if (r(t97) == .) local pll_t_fini = 0
	else local pll_t_fini = r(t97)
	
	qui timer list
	return local  pll_seeds="`pllseeds'"
	return scalar pll_errs = `nerrors'
	return local  pll_dir "`pll_dir'"
	return scalar pll_t_reps = `pll_t_reps'
	return scalar pll_t_setu = `pll_t_setu'
	return scalar pll_t_calc = `pll_t_calc'
	return scalar pll_t_fini = `pll_t_fini'
	return local pll_id = "`parallelid'"
	
	if `nerrors' {
		di as err "`nerrors' child processes encountered errors. Throwing last error."
		exit `pll_last_error'
	}
end

////////////////////////////////////////////////////////////////////////////////
// Cleans all files generated by parallel
// If you want to keep the logs, then specify -, nologs-
program def parallel_clean
	version 11.0
	syntax [, Event(string) All Force nologs]
		
	if (length("`event'") != 0 & length("`all'") != 0) {
		di as error `"invalid syntax: Using -pll_id- and -all- jointly is not allowed."'
		exit 198
	}
	local do_logs = ("`logs'"!="nologs")
	mata: parallel_clean("`event'", `=length("`all'") > 0', `=length("`force'") > 0', `do_logs')
end

////////////////////////////////////////////////////////////////////////////////
// Sets the number of clusters as a global macro
program parallel_setclusters
	version 11.0
	syntax anything(name=nclusters)  [, Force Statapath(string asis) Gateway(string) Includefile(string) procexec(int 2)]
	
	_assert inlist(`procexec',0,1,2), msg("procexec() must be 0, 1, or 2") rc(198)
	cap parallel_setclusters
	local nproc = int(real("`r(numprocessors)'"))
	if "`nclusters'"=="default"{
		_assert `nproc'!=., msg("Couldn't determine number of available processors for default configuration.")
		local nclusters = max(floor(`nproc'*3/4),1)
	}
	else{
		local nclusters = int(real(`"`nclusters'"'))
		_assert (`nclusters'>0 & `nclusters'!=.),  msg(`"Not allowed: "#" Should be a positive number"') rc(109)
	}
	global USE_PROCEXEC = `procexec'
	
	local force = (length("`force'")>0)
	mata: parallel_setclusters(`nclusters', `force', `nproc')
	mata: st_local("error", strofreal(parallel_setstatapath(`"`statapath'"', `force')))
	_assert (!`error'), msg("Can not set Stata directory, try using -statapath()- option") rc(`error')
	
	if "`c(mode)'"=="batch" & "`c(os)'"=="Windows" & "$USE_PROCEXEC"=="0" {
		if `"`gateway'"'=="" local gateway "pll_gateway.sh"

		cap confirm file `"`gateway'"'
		_assert `=!_rc', msg(`"On Windows batch-mode with command-line process execution, requires a gateway file is required but not found (path: `c(pwd)')"') rc(`=_rc')
		global PLL_GATEWAY_FNAME `"`gateway'"'
	}
	
	if `"`includefile'"'!=""{
		cap confirm file `"`includefile'"'
		_assert `=!_rc', msg("Can not find the include file (`includefile').") msg(`=_rc')
		global PLL_INCLUDE_FILE `"`includefile'"'
	}
end


////////////////////////////////////////////////////////////////////////////////
// Exports

// Exports a copy of programs
program def program_export
	version 11.0
	syntax using/ [,Programlist(string) Inname(string)]
	
	mata: program_export("`using'", "`programlist'", "`inname'")
end


////////////////////////////////////////////////////////////////////////////////
// Appends the clusterized dataset
program def parallel_fusion
	version 11.0
	syntax anything(name=parallelid) , clusters(integer) [keepusing(string)]
	
	cap use "__pll`parallelid'_dta0001.dta", clear
	if (_rc){
		di as err "No dataset for instance 0001."
		exit _rc
	}
	local sortlist: sortedby
	
	forval i = 2/`clusters' {
		cap append using `"__pll`parallelid'_dta`=string(`i',"%04.0f")'.dta"'
		if (_rc){	
			di as err "No dataset for instance `=string(`i',"%04.0f")'."
			exit _rc
		}
	}
	
	/* If it just used a set of variables */
	if (length("`keepusing'")) {
		qui merge 1:1 __pllnobs`parallelid' using __pll`parallelid'_dataset, keep(3) nogen
		drop __pllnobs`parallelid'
	}
	
	//restore the sort
	if "`sortlist'"!="" sort `sortlist'	
	
end

////////////////////////////////////////////////////////////////////////////////
// Checks whether the user pressed break inside a loop
program def parallel_break
	version 11.0
	mata: parallel_break()
end

