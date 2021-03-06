*! version 1.16.4.20 20abr2016
* Generates the corresponding dofiles

/**oxygen
 * @brief Writes a fully functional do-file to be runned by -parallel_run()-.
 * @param inputname Name of a do-file or string with a commando to be runned.
 * @param parallelid Parallel instance ID.
 * @param nchildren Number of child processes (files).
 * @param prefix Whether this is a command (prefix != 0) or a do-file.
 * @param matsave Whether to include or not MATA objects.
 * @param getmacros Whete to include or not Globals.
 * @param seed Seed to be used (list)
 * @param randtype If no seeds provided, type of algorithm used to generate the seeds
 * @param nodata Wheter to load (1) data or not.
 * @param folder Folder where the do-file should be running.
 * @param programs A list of programs to be used within each child process.
 * @param processors Number of statamp processors to use in each child process.
 * @returns As many do-files as child processes used.
 */
mata:

real scalar parallel_temp_sequence(string scalar id_part){
	real rowvector ascii_codes, nice_ind
	real scalar num, i, exp
	ascii_codes = ascii(id_part)
	nice_ind = ascii_codes :- ((ascii_codes :> 57):*7:+48) /*zero-based and reindexed (letters smashed down to numbers)*/
	num = 1
	for(i=length(nice_ind); i>=1; i--){
		exp = length(nice_ind)-i
		num = num+nice_ind[i]*(36^exp)
	}
	return(num)
}

real scalar parallel_write_do(
	string scalar inputname,
	string scalar parallelid,
	| real scalar nchildren,
	real   scalar prefix,
	real   scalar matasave,
	real   scalar getmacros,
	string scalar seed,
	string scalar randtype,
	real   scalar nodata,
	string scalar folder,
	string scalar programs,
	real scalar processors,
	real scalar work_around_no_cwd,
	string scalar output_opts
	)
{
	real vector input_fh, output_fh
	string scalar line, fname, nexttempname
	string scalar memset, maxvarset, matsizeset
	real scalar i, n_prev_tempnames
	string colvector seeds
	string scalar new_lib, output_opts_final
	string rowvector output_opts_toks

	// Checking optargs
	if (matasave == J(1,1,.)) matasave = 0
	if (prefix == J(1,1,.)) prefix = 1
	if (getmacros == J(1,1,.)) getmacros = 0
	if (nchildren == J(1,1,.)) {
		if (strlen(st_global("PLL_CHILDREN"))) nchildren = strtoreal(st_global("PLL_CHILDREN"))
		else {
			errprintf("You haven't set the number of child processes\nPlease set it with -{cmd:parallel initialize} {it:#}-}\n")
			return(198)
		}
	}
	
	/* Check seeds and seeds length */
	if (seed == J(1,1,""))
	{
		seeds = parallel_randomid(5, randtype, 0, nchildren, 1)
		st_local("pllseeds", invtokens(seeds'))
	}
	else
	{
		st_local("pllseeds", seed)
		seeds = tokens(seed)
		/* Checking seeds length */
		if (length(seeds) > nchildren)
		{
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nchildren)
			return(123)
		}
		else if (length(seeds) < nchildren)
		{
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nchildren)
			return(122)
		}
	}
	if (nodata == J(1,1,.)) nodata = 0
	if (folder == J(1,1,"")) folder = c("pwd")

	real scalar progsave
	if (programs !="") progsave = 1
	else progsave = 0
	
	/* Checks for the MP version */
	if (!c("MP") & processors != 0 & processors != J(1,1,.)) display("{result:Warning:}{text: processors option ignored...}")
	else if (processors == J(1,1,.) | processors == 0) processors = 1
	
	if (work_around_no_cwd == J(1,1,.))  work_around_no_cwd=0

	real scalar err
	err = 0
	if (progsave)  err = parallel_export_programs(folder+"__pll"+parallelid+"_prog.do", programs, folder+"__pll"+parallelid+"_prog.log")
	if (getmacros) parallel_export_globals(folder+"__pll"+parallelid+"_glob.do")

	if (err)
	{
		errprintf("An error has occurred while exporting -programs-")
		return(err)
	}
	
	//figure out the tempname state
	nexttempname=st_tempname()
	n_prev_tempnames = parallel_temp_sequence(substr(nexttempname,3))-1
	
	for(i=1;i<=nchildren;i++) 
	{
		// Sets dofile
                fname = folder+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
		if (fileexists(fname)) unlink(fname)
		output_fh = fopen(fname, "w", 1)
		
		// Step 1
		fput(output_fh, "capture {")
		fput(output_fh, "clear")
		if (c("MP")) fput(output_fh, "set processors "+strofreal(processors))
		fput(output_fh, `"cd ""'+folder+`"""')
		
		//Copy over the adopath & matalibs order
		//PERSONAL & PLUS are the most likely to be overwritten and referenced in S_ADO. (could do others)
		fput(output_fh, `"sysdir set PERSONAL ""' + st_global("c(sysdir_personal)") +`"""')
		fput(output_fh, `"sysdir set PLUS ""' + st_global("c(sysdir_plus)") +`"""')
		if(work_around_no_cwd==0){
			fput(output_fh, "global S_ADO = `"+`"""'+st_global("S_ADO")+`"""'+"'")
		}
		else{
			fput(output_fh, "global S_ADO = `"+`"""'+st_global("S_ADO")+`";.""'+"'")
		}
		fput(output_fh, "mata: mata mlib index")
		new_lib = (length(st_global("c(matalibs)"))>0 ? ";" : "")+"l__pll"+parallelid+"_mlib"
		//   c(matalibs) will outputted at the time parallel is called (not when child process is called)
		// so the final order will be the original+new_lib. The 'mlib index' command above ensures we can
		// find the new lib. And this next line is needed because if 'keep' is used with previous -parallel-
		// calls then we don't want to include all the other temporary libraries.
		fput(output_fh, `"mata: mata set matalibs ""'+st_global("c(matalibs)")+new_lib+`"""')
		
		fput(output_fh, "set seed "+seeds[i])
		
		if (st_global("PLL_INCLUDE_FILE")!=""){
			fput(output_fh, `"include ""'+st_global("PLL_INCLUDE_FILE")+`"""')
		}

		/* Parallel macros to be used by the current user */
		fput(output_fh, `"noi di "{hline 80}""')
		fput(output_fh, `"noi di "Parallel computing with Stata""')
		fput(output_fh, `"noi di "{hline 80}""')
		fput(output_fh, sprintf(`"noi di \`"cmd/dofile   : "%s""'"', inputname))
		fput(output_fh, sprintf(`"noi di "pll_id       : %s""',parallelid))
		fput(output_fh, sprintf(`"noi di "pll_instance : %g/%g""',i,nchildren))
		fput(output_fh,         `"noi di "tmpdir       : \`c(tmpdir)'""')
		fput(output_fh,         `"noi di "date-time    : \`c(current_time)' \`c(current_date)'""')
		fput(output_fh,         `"noi di "seed         : \`c(seed)'""')
		fput(output_fh, `"noi di "{hline 80}""')
		fput(output_fh, "local pll_instance "+strofreal(i))
		fput(output_fh, "local pll_id "+parallelid)
		fput(output_fh, "global pll_instance "+strofreal(i))
		fput(output_fh, "global pll_id "+parallelid)
		
		// Data requirements
		if (!nodata)
		{
			if (c("MP") | c("SE")) 
			{
				// Building data limits
				memset     = sprintf("%9.0f",c("memory")/nchildren)
				maxvarset  = sprintf("%g",c("maxvar"))
				matsizeset = sprintf("%g",c("matsize"))

				// Writing data limits
				if (!c("MP")) fput(output_fh, "set memory "+memset+"b")
				fput(output_fh, "set maxvar "+maxvarset)
				fput(output_fh, "set matsize "+matsizeset)
			}
		}
		
		if (n_prev_tempnames>0) fput(output_fh, `"mata: for(i=1;i<="'+strofreal(n_prev_tempnames)+`";i++) PLL_QUIET = st_tempname()"')
		
		/* Checking data setting is just fine */
		fput(output_fh, "}")
		fput(output_fh, "local result = _rc")
		fput(output_fh, "if (c(rc)) {")
		fput(output_fh, `"cd ""'+folder+`"""')
		fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while setting memory")"')
		fput(output_fh, "clear")
		fput(output_fh, "exit")
		fput(output_fh, "}")
		
		// Loading programs
		if (progsave)
		{
			fput(output_fh, sprintf("\n* Loading Programs *"))
			fput(output_fh, "capture {")
			fput(output_fh, `"run ""'+folder+"__pll"+parallelid+`"_prog.do""')
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading programs")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key 
		fput(output_fh, sprintf("\n* Checking for break *"))
		fput(output_fh, "mata: parallel_break()") */
		
		// Mata objects loading
		if (matasave)
		{
			fput(output_fh, sprintf("\n* Loading Mata Objects *"))
			fput(output_fh, "capture {")
			fput(output_fh, `"mata: mata matuse ""'+folder+"__pll"+parallelid+`"_mata.mmat""')
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading mata objects")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n* Checking for break *"))
		fput(output_fh, "mata: parallel_break()")
		
		// Globals loading
		if (getmacros)
		{
			fput(output_fh, sprintf("\n* Loading Globals *"))
			fput(output_fh, "capture {")
			fput(output_fh, `"cap run ""'+folder+"__pll"+parallelid+`"_glob.do""')
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"  cd ""'+folder+`"""')
			fput(output_fh, `"  mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading globals")"')
			fput(output_fh, "  clear")
			fput(output_fh, "  exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n* Checking for break *"))
		fput(output_fh, "mata: parallel_break()")
				
		// Step 2		
		fput(output_fh, "capture {")
		fput(output_fh, "  noisily {")
		
		// If it is not a command, i.e. a dofile
		if (!nodata){
			fput(output_fh, `"    use ""'+folder+"__pll"+parallelid+`"_dataset" if _"'+parallelid+"cut == "+strofreal(i))
			fput(output_fh, "    drop _"+parallelid+"cut")
		}
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n* Checking for break *"))
		fput(output_fh, "mata: parallel_break()")
		
		if (!prefix) {
			input_fh = fopen(inputname, "r", 1)
			
			while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, "    "+line)	
			fclose(input_fh)
		} // if it is a command
		else{
			//convert potential output_opts
			output_opts_toks = tokens(output_opts)
			output_opts_toks = output_opts_toks :+ "(" :+ folder :+ "__pll" :+ parallelid :+ "_out_" :+ output_opts_toks :+ strofreal(i,"%04.0f") :+ ")"
			output_opts_final = invtokens(output_opts_toks, " ")
			
			fput(output_fh, "    "+inputname+" "+output_opts_final)
		}
		
		fput(output_fh, "  }")
		fput(output_fh, "}")

		/* Checking programs loading is just fine */
		fput(output_fh, "if (c(rc)) {")
		fput(output_fh, `"  cd ""'+folder+`"""')
		fput(output_fh, `"  mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while running the command/dofile")"')
		fput(output_fh, "  clear")
		fput(output_fh, "  exit")
		fput(output_fh, "}")

		fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while executing the command")"')

		if (!nodata) fput(output_fh, `"save ""'+folder+"__pll"+parallelid+"_dta"+strofreal(i,"%04.0f")+`"", replace"')
		
		// Step 3
		fput(output_fh, `"cd ""'+folder+`"""')
		fclose(output_fh)
	}
	return(0)
}
end

