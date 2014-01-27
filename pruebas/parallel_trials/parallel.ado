*! version 0.12.12  11dec2012
/*
////////////////////////////////////////////////////////////////////////////////
CHANGE LOG
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
	gettoken x 0 : 0, parse(":") 
	local notprefix = (length(`"`0'"')) == 0
	if  (`notprefix') { // If not prefix
	
		// Gets the subcommand
		gettoken subcmd 0 : x
		
		if "`subcmd'" == "do" {                // parallel do (file path should always be enclose in brackets)
			parallel_`subcmd' `0'
		}
		else if "`subcmd'" == "setclusters" {  // parallel setclusters
			parallel_`subcmd' `0'
		}
		else if "`subcmd'" == "setstatadir" {  // parallel setstatadir
			parallel_`subcmd' `0'
		}
		else if regexm("`subcmd'", "^clean[,]?") {        // parallel clean
			parallel_`subcmd' `0'
		}
		else {
			di as err `"`subcmd' invalid subcommand"'
			exit 198
		}	
	}
	else {             // if prefix
	
		// Gets the options (if these exists) of parallel
		gettoken x options : x, parse(",") 
		local 0 = regexr(`"`0'"', "^[:]", "")
		parallel_do "`0'", `options' prefix
	}
end

////////////////////////////////////////////////////////////////////////////////
// Sets the number of clusters as a global macro
cap program drop parallel_setclusters
program parallel_setclusters
	syntax anything(name=nclusters)  [, Force]
	
	// checks for normalizepath (required)
	cap normalizepath
	if _rc == 199 cap ssc install normalizepath
	
	local nclusters = real(`"`nclusters'"')
	
	if !(`nclusters' == .) {
		if (`nclusters' <= 8) | ((`nclusters' > 8) & length("`force'") != 0) {
			global PLL_CLUSTERS = floor(`nclusters')
		}
		else {
			di as error `"Too many clusters: If you want to set more than 8 clusters you should use the option "force""'
			exit 912
		}
	}
	else {
		di as error `"Not allow: "#" Should be a number"'
		exit 109
	}
	
	di as txt "N Cluster: " as res "$PLL_CLUSTERS"
	
	// Is it 64 bits?
	if c(bit) == 64 local bit = "-64"
	
	// Sets the right path to stata
	if "$S_OS" == "Windows" {
		if `c(MP)' global PLL_DIR ""`c(sysdir_stata)'StataMP`bit'.exe""
		else if `c(SE)' global PLL_DIR ""`c(sysdir_stata)'StataSE`bit'.exe""
		else if "`c(flavor)'" == "Small" global PLL_DIR ""`c(sysdir_stata)'StataSM`bit'.exe""
		else if "`c(flavor)'" == "IC" global PLL_DIR ""`c(sysdir_stata)'Stata`bit'.exe""
		
		// Checks if it exists
		cap confirm file $PLL_DIR
		if _rc {
			di as error `"Can not set Stata directory, try using "parallel setstatadir" syntax"'
			global PLL_DIR ""
			exit 601
		}
	}
	else {
		if `c(MP)' global PLL_DIR ""`c(sysdir_stata)'stata-mp""
		else if `c(SE)' global PLL_DIR ""`c(sysdir_stata)'stata-se""
		else if "`c(flavor)'" == "Small" global PLL_DIR ""`c(sysdir_stata)'stata-sm""
		else if "`c(flavor)'" == "IC" global PLL_DIR ""`c(sysdir_stata)'stata""
	}
	
	di as txt "Stata dir: " as res $PLL_DIR
end

// Sets the stata.exe location for windows
cap program drop parallel_setstatadir
program parallel_setstatadir
	args statadir
	cap confirm file "`statadir'"
	if "$S_OS" == "Windows" {
		if !_rc global PLL_DIR ""`statadir'""
		else {
			di as error "Invalid File: " `macval(statadir)' " doesn't exists"
			exit 601
		}
	}
	else {
		global PLL_DIR ""`statadir'""
	}
	di as txt "Stata dir: " as res $PLL_DIR
end

////////////////////////////////////////////////////////////////////////////////
// Builds a do file including every program load in the sesion
capture program drop reachprograms
program def reachprograms

	args inputname outputname

	cap log close `inputname'
	program drop _allado
	
	log using "`inputname'.log", replace text name(`inputname')
	di "program list"
	program list
	di "log close"
	
	log close `inputname'

	mata: reachprograms("`inputname'.log", "`outputname'")
	
end

////////////////////////////////////////////////////////////////////////////////
capture mata:mata drop reachprograms()
mata:
void reachprograms(string scalar inputname, string scalar outputname)
{
	real vector input_fh, output_fh
	real scalar err, LOGINIT, LOGCLOSE, NPROGRAMS, WEIRDPROG, WRITE
	string scalar NEWLINE, line, line_to_write, line_prev

	stata("cap mata: _fclose(input_fh)")
	stata("cap mata: _fclose(output_fh)")
	
	err = _unlink(outputname)
		
	input_fh = _fopen(inputname, "r")
	output_fh = _fopen(outputname, "w")

	LOGINIT = 0
	LOGCLOSE = 0
	NPROGRAMS = 0
	NEWLINE = "(^[ ]?[0-9]*\. >)|(^[ ]*> )"
	WEIRDPROG = 0
	
	// Reads the first line
	line = fget(input_fh)
	line_to_write = ""
	
	while (line!=J(0,0,"")) {
	
		// From the second line on
		line_prev = line
		

		// Checks for weird programs shuch as "0while"
		if ((WEIRDPROG = regexm(line, "^[0-9]+[A-Za-z0-9_]*:$")) == 1) {
			WEIRDPROG = 0
			while ((line!=J(0,0,"")) & !WEIRDPROG) {
				WEIRDPROG = line == ""
				line = fget(input_fh)
			}
		}

		if (line != J(0,0,"")) {
			if (regexm(line, NEWLINE)) {
				line_to_write = line_to_write + "" + regexr(line, NEWLINE, "")
				line = fget(input_fh)
			}
			else {
				line_to_write = line
				line = fget(input_fh)
			}
			
			if (line != J(0,0,"")) {
				if (!regexm(line, NEWLINE)) {
				
					// Checks if isnt the last line (for us to write)
					if (regexm(line_prev, "^program list$")) LOGINIT = 1
					if (regexm(line, "^log close$")) LOGCLOSE = 1
					
					//line = fget(input_fh)
					if (line == J(0,0,"")) WRITE = 0
					else WRITE = !regexm(line, NEWLINE)
					
					if (((LOGINIT + LOGCLOSE) == 1) & WRITE) {
					
						if (regexm(line_to_write, "^[A-Za-z0-9_]*[ ]?,?([ ]?[A-Za-z0-9_]*[ ]?)?:$")) {
							if (++NPROGRAMS > 1) {
								fput(output_fh, "end")
							}		
							line_to_write = "program def " + subinstr(line_to_write, ":", "", .)
							fput(output_fh, line_to_write)
						}
						else if (!regexm(line_to_write, "^program list$")) {
							line_to_write = regexr(line_to_write, "^[ ]*[0-9]*\.", "")
							fput(output_fh, line_to_write)			
						}
					}
				}
			}
		}
	}

	err = _fput(output_fh, "end")

	err = _fclose(output_fh)
	err = _fclose(input_fh)
}

end

////////////////////////////////////////////////////////////////////////////////
// Appends the clusterized dataset
cap program drop parallel_fusion
program def parallel_fusion
	args clusters parallelid
	
	capture {
		use "__pll`parallelid'dta1.dta", clear
		
		forval i = 2/`clusters' {
			append using "__pll`parallelid'dta`i'.dta"
		}
	}
end


////////////////////////////////////////////////////////////////////////////////
// Splits the dataset into clusters
cap program drop spliter
program def spliter
	args xtstructure parallelid sorting force
	
	if length("$PLL_CLUSTERS") == 0 {
		di as err "Number of clusters not fixed." as text " Set the number of clusters with " _newline as err "{cmd:parallel setclusters #}"
		exit 198
	}
	
	quietly {
	
		if length("`xtstructure'") != 0 {
			// Checks wheather if the data is in the correct sorting
			if !`sorting' & !`force' {
				error 5
			}
		
			// Generating the xtstructure list for the "if"
			foreach var in `xtstructure' {
				local ifxt "`ifxt' & `var'[_n-1] == `var'"	
			}
		}
	
		local size = floor(_N/$PLL_CLUSTERS)
		cap drop _`parallelid'cut
		gen _`parallelid'cut = .
		forval i = 1/$PLL_CLUSTERS {
			replace _`parallelid'cut = `i' if _`parallelid'cut == . & ((_n < (`size'*(`i'))) | ($PLL_CLUSTERS == `i'))
			if length("`xtstructure'") != 0 replace _`parallelid'cut = `i' if ///
				(_`parallelid'cut == . & _`parallelid'cut[_n-1] != .) `ifxt'
		}
		save __pll`parallelid'dataset, replace
		
		clear
	}
	
end

////////////////////////////////////////////////////////////////////////////////
// MAIN PROGRAM
cap program drop parallel_do
program def parallel_do, rclass
	syntax anything(name=dofile) [, by(string) Keep KEEPLast prefix Force Programs Mata NOGlobal KEEPTiming Seeds(numlist) NOData]
		
	if length("`keeptiming'") == 0 {
		timer clear 98
		timer clear 99
	}
	
	timer on 98
		
	if length("$PLL_CLUSTERS") == 0 {
		di as txt "You haven set the number of clusters" _newline as txt "Please set it with: " "{cmd:parallel setclusters} {it:#}"
		exit 198
	}
	
	// Delets last parallel instance ran
	if length("`keeplast'") != 0 cap parallel_clean, e(`r(pll_id)')
	
	// Gets some global values
	local sfn = "$S_FN"
	
	// Gets the directory where to work at
	if length("`prefix'") == 0 {	
		cap normalizepath `dofile'
		local pll_dir = r(filedir)
		local dofile = r(filename)
	}
	else local pll_dir = c(pwd)
	
	local initialdir = c(pwd)
	cd "`pll_dir'"
	
	if length("`by'") != 0 {
		local sortlist: sortedby
		local sorting = regexm("`sortlist'","^`by'")
	}
	
	// Creates a unique ID for the process
	local parallelid = 10000+int((99999-10000+1)*runiform())
	
	// Checks weather to split a dataset or not
	local nodata = length("`nodata'") > 0
	
	// Generates database clusters
	if length("`force'") != 0 local force = 1
	else local force = 0
	if (!`nodata') spliter "`by'" "`parallelid'" "`sorting'" `force'
	
	// Starts building the files
	quietly {
	
		// Saves mata objects
		if length("`mata'") != 0 {
			mata: mata mlib create l__pll`parallelid'mlib, replace
			cap mata: mata mlib add l__pll`parallelid'mlib *()
			cap mata: mata matsave __pll`parallelid'mata.mmat *, replace			
			local matasave = _rc
		}
		else local matasave = 1
		
		// Builds macro list
		local tracing = "`c(trace)'" == "on"
		local moreset = "`c(more)'" == "on"
			
		if `moreset' set more off
		if `tracing' set trace off
		if length("`noglobal'") == 0 {
			cap log close log`parallelid'
			log using __pll`parallelid'globals.log, replace text name(log`parallelid')
			noisily macro dir
			log close log`parallelid'
			local getmacros = 1
		}
		else local getmacros = 0 
		
		// Saves loaded functions
		if length("`programs'") != 0 noisily reachprograms "__pll`parallelid'prog" "__pll`parallelid'prog.do"
		if `moreset' set more on
		if `tracing' set trace on
		
		// Gets some important parameters
		local memory = ceil(`c(memory)'/$PLL_CLUSTERS)
		local maxvar = `c(maxvar)'
		local matsize = `c(matsize)'
	
		// Building number lists
		if length("`seeds'") != 0 {
			local rep = 0
			foreach seed in `seeds' {
				local pllseed`++rep' = `seed'
			}
		}

		// If using "parallel do"
		if length("`prefix'") == 0 {
			forval i = 1/$PLL_CLUSTERS {
				mata: translatedofile("`dofile'", "__pll`parallelid'do`i'.do", "__pll`parallelid'dta`i'", `matasave', "`memory'b", "`maxvar'", "`matsize'", 0, "`parallelid'", "`i'", `getmacros', "`pllseed`i''", `nodata', "`pll_dir'")
			}
		}
		// If using "parallel :"
		else {
			forval i = 1/$PLL_CLUSTERS {
				mata: translatedofile(`dofile', "__pll`parallelid'do`i'.do", "__pll`parallelid'dta`i'", `matasave', "`memory'b", "`maxvar'", "`matsize'", 1, "`parallelid'", "`i'", `getmacros', "`pllseed`i''", `nodata', "`pll_dir'")
			}		
		}
	}
		
	// Message
	di as txt "Parallel Computing with Stata " as res "(by GVY)" _newline as txt "Clusters: " as res "$PLL_CLUSTERS" _newline as txt "ID: " as res "`parallelid'"
	
	// Writes the shell file
	if "$S_OS" != "Windows" {
		cap rm __pll`parallelid'shell.sh
		file open __pll`parallelid'shell using __pll`parallelid'shell.sh, write replace
		file write __pll`parallelid'shell "echo Stata instances PID:" _newline
		forval i = 1/$PLL_CLUSTERS {
			file write __pll`parallelid'shell `"$PLL_DIR"'" -b do __pll`parallelid'do`i'.do &" _newline
		}
			
		file close __pll`parallelid'shell
		
		// Ends setup time
		timer off 98
			
		// Runs the shell file
		timer on 99
		shell tcsh __pll`parallelid'shell.sh&

		parallel_finito "`parallelid'" "$PLL_CLUSTERS"
		timer off 99
	}
	else {
	
		// Ends setup time
		timer off 98
		
		// Runs the shell file
		timer on 99
		forval i = 1/$PLL_CLUSTERS {
			winexec $PLL_DIR /e /q do __pll`parallelid'do`i'.do
		}
		parallel_finito "`parallelid'" "$PLL_CLUSTERS"
		timer off 99
	}
	
	timer on 97
	// Paste the databases
	if (!`nodata') parallel_fusion "$PLL_CLUSTERS" "`parallelid'"
	
	// Restores original S_FN (file name) value
	global S_FN = "`sfn'"
	
	cap drop _`parallelid'cut
	
	if "$S_OS" == "Windows" local eraser "erase /f /q"
	else local eraser "rm -f"
	qui cap !`eraser' __pll`parallelid'finito*&`eraser' __pll`parallelid'globals.log&`eraser' __pll`parallelid'prog.log&`eraser' __pll`parallelid'shell.sh&
	
	if length("`keep'") == 0 & length("`keeplast'") == 0 parallel_clean, e("`parallelid'")
	
	timer off 97
	
	qui timer list
	return local  pll_dir "`pll_dir'"
	return scalar pll_t_reps = `r(nt99)'
	return scalar pll_t_setu = `r(t98)'
	return scalar pll_t_calc = `r(t99)'
	return scalar pll_t_fini = `r(t97)'
	return scalar pll_id = `parallelid'
	return scalar pll_n = $PLL_CLUSTERS
	
	qui cd "`initialdir'"
end

////////////////////////////////////////////////////////////////////////////////
// Generates the corresponding dofiles
cap mata: mata drop	translatedofile()
mata:
void translatedofile(
	string scalar inputname, 
	string scalar outputname, 
	string scalar dtaname, 
	real   scalar matasave,
	string scalar memory,
	string scalar maxvar,
	string scalar matsize,
	real   scalar cmd,
	string scalar parallelid,
	string scalar iter,
	real   scalar getmacros,
	string scalar seed,
	real   scalar nodata,
	string scalar folder
	)
{
	real vector input_fh, output_fh
	real scalar err
	string scalar line

	// Sets dofile
	stata("cap mata: _fclose(output_fh)")
	err = _unlink(outputname)
	output_fh = fopen(outputname, "w")
	
	// Step 1
	fput(output_fh, "clear all")
	fput(output_fh, "cd "+folder)
	
	if (strlen(seed) != 0) fput(output_fh, "set seed "+seed)
	
	if (!nodata) {
		fput(output_fh, "set memory "+memory)
		fput(output_fh, "cap set maxvar "+maxvar)
		fput(output_fh, "cap set matsize "+matsize)
		fput(output_fh, "use __pll"+parallelid+"dataset if _"+parallelid+"cut == "+iter)
	}
	
	fput(output_fh, "cap run __pll"+parallelid+"prog.do")
	
	if (matasave == 0) fput(output_fh, "mata: mata matuse __pll"+parallelid+"mata.mmat")
	
	if (getmacros) reachmacros("__pll"+parallelid+"globals.log", output_fh)
	
	fput(output_fh, "local pll_instance "+iter)
	fput(output_fh, "local pll_id "+parallelid)
	fput(output_fh, "capture {")
	fput(output_fh, "noisily {")
	if (!cmd) {
		stata("cap mata: _fclose(input_fh)")
		input_fh = fopen(inputname, "r")
		
		while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, line)	
		fclose(input_fh)
	}
	else fput(output_fh, inputname)
	
	fput(output_fh, "}")
	fput(output_fh, "}")
	if (!nodata) fput(output_fh, "save "+dtaname+", replace")
	
	// Step 3
	fput(output_fh, "local result = _rc")
	fput(output_fh, "cd "+folder)
	fput(output_fh, "file open fh using __pll"+parallelid+"finito"+iter+", w replace")
	fput(output_fh, `"file write fh ""'+"`"+"result"+"'"+`"""')
	fput(output_fh, "file close fh")
	fclose(output_fh)
}
end

////////////////////////////////////////////////////////////////////////////////
// Cleans all files generated by parallel
cap program drop parallel_clean
program def parallel_clean
	syntax [, Event(numlist integer >0 max=1) All]
	
	local event = "`pll_id'"
		
	if "$S_OS" == "Windows" local eraser "erase /f /q"
	else local eraser "rm -f"
	
	// Rms every file generated by parallel
	if length("`event'") == 0 & length("`all'") != 0 {
		#delim ;
		cap qui shell
			`eraser' __pll*&
			`eraser' l__pll*mlib.mlib;
		#delim cr
	}
	// Rms every file generated by parallel of an especific instance
	else if length("`event'") != 0 & length("`all'") == 0 {
		#delim ;
		cap qui shell
			`eraser' __pll`event'*&
			`eraser' l__pll`event'mlib.mlib;
		#delim cr
	}
	// Rms every file generated by parallel of the last instance runned
	else if length("`event'") == 0 & length("`all'") == 0 {
		#delim ;
		cap qui shell
			`eraser' __pll`r(pll_id)'*&
			`eraser' l__pll`r(pll_id)'mlib.mlib;
		#delim cr
	}
	else if length("`event'") != 0 & length("`all'") != 0 {
		di as error `"invalid syntax: Using "#" and "all" jointly is not allowed."'
		exit 198
	}
end

////////////////////////////////////////////////////////////////////////////////
// Waits until the 
cap program drop parallel_finito
program def parallel_finito, rclass
	args parallelid clusters

	local suberrors = 0
	forval i = 1/`clusters' {
		local ready = 0
		local inf = 1
		while !`ready' & `inf' <= 100000 {
			cap findfile "__pll`parallelid'finito`i'"
			
			local ++inf
			if _rc == 0 {
				file open fh using "__pll`parallelid'finito`i'", r
				file read fh rcode
				if `rcode' != 0 {
					di as res "`i'/`clusters' " as txt "cluster finished with an error {stata search r(`rcode'):r(`rcode')}..."
					return scalar suberr`i' = `rcode'
					local `++suberrors'
				}
				else di as res "`i'/`clusters' " as txt "cluster finished without any error..."
				file close fh 
				local ready = 1
			}
			else sleep 100
		}
	}
	return scalar suberrors = `suberrors'
end

////////////////////////////////////////////////////////////////////////////////
// Looks for global macros and writes to the dofile
cap mata: mata drop reachmacros()
mata:
void reachmacros(
	string scalar inputname, 
	real   scalar outputname
	)
{
	real   scalar ismacro, forbidden, input_fh
	string scalar line, macname, macvalu, typeofmacro, REGEX, FORBIDDEN

	// Sets dofile
	stata("cap mata: _fclose(input_fh)")
	input_fh = fopen(inputname, "r")
	
	// Step 1
	REGEX = "^([0-9a-zA-Z_]*)([:][ ]*)(.*)"
	FORBIDDEN = "(^)(S[_]FNDATE|S[_]FN|F[0-9]|S[_]level|S[_]ADO|S[_]FLAVOR|S[_]OS|S[_]MACH)([ ]*.*$)"
	
	line = fget(input_fh)
	while (line!=J(0,0,""))
	{
		// Check wheater it is a macro or not (and not system macros)
		forbidden = regexm(line, FORBIDDEN)
		ismacro = regexm(line, REGEX)
		
		if (ismacro & !forbidden)
		{
			macname = regexs(1)
			
			// Checks wheather if it is a local or global macro
			if (!regexm(macname, "^[_]"))
			{
				macvalu = st_macroexpand("$"+macname)
				typeofmacro = "global "
				line = typeofmacro+macname+" "+macvalu
				fput(outputname, line)
			}
		}
		line = fget(input_fh)
	}
	
	fclose(input_fh)
}
end
