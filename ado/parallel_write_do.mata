*! version 0.13.10.7  7oct2013
* Generates the corresponding dofiles

/**oxygen
 * @brief Writes a fully functional do-file to be runned by -parallel_run()-.
 * @param inputname Name of a do-file or string with a commando to be runned.
 * @param parallelid Parallel instance ID.
 * @param ncluster Number of clusters (files).
 * @param prefix Whether this is a command (prefix != 0) or a do-file.
 * @param matsave Whether to include or not MATA objects.
 * @param getmacros Whete to include or not Globals.
 * @param seed Seed to be used (list)
 * @param randtype If no seeds provided, type of algorithm used to generate the seeds
 * @param nodata Wheter to load (1) data or not.
 * @param folder Folder where the do-file should be running.
 * @param programs A list of programs to be used within each cluster.
 * @param processors Number of statamp processors to use in each cluster.
 * @returns As many do-files as clusers used.
 */
mata:
real scalar parallel_write_do(
	string scalar inputname,
	string scalar parallelid,
	| real scalar nclusters,
	real   scalar prefix,
	real   scalar matasave,
	real   scalar getmacros,
	string scalar seed,
	string scalar randtype,
	real   scalar nodata,
	string scalar folder,
	string scalar programs,
	real scalar processors
	)
{
	real vector input_fh, output_fh
	string scalar line, fname
	string scalar memset, maxvarset, matsizeset
	real scalar i
	string colvector seeds

	// Checking optargs
	if (matasave == J(1,1,.)) matasave = 0
	if (prefix == J(1,1,.)) prefix = 1
	if (getmacros == J(1,1,.)) getmacros = 0
	if (nclusters == J(1,1,.)) {
		if (strlen(st_global("PLL_CLUSTERS"))) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
		else {
			errprintf("You haven't set the number of clusters\nPlease set it with -{cmd:parallel setclusters} {it:#}-}\n")
			return(198)
		}
	}
	
	/* Check seeds and seeds length */
	if (seed == J(1,0,"") | seed == "")
	{
		seeds = parallel_randomid(5, randtype, 0, nclusters, 1)
	}
	else
	{
		seeds = tokens(seed)
		/* Checking seeds length */
		if (length(seeds) > nclusters)
		{
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
			return(123)
		}
		else if (length(seeds) < nclusters)
		{
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
			return(122)
		}
	}
	if (nodata == J(1,1,.)) nodata = 0
	if (folder == J(1,1,"")) folder = c("pwd")

	real scalar progsave
	if (strlen(programs)) progsave = 1
	else progsave = 0
	
	/* Checks for the MP version */
	if (!c("MP") & processors != 0 & processors != J(1,1,.)) display("{it:{result:Warning:} processors option ignored...}")
	else if (processors == J(1,1,.) | processors == 0) processors = 1

	if (progsave) parallel_export_programs(folder+"/__pll"+parallelid+"_prog.do", programs)
	if (getmacros) parallel_export_globals(folder+"/__pll"+parallelid+"_glob.do")
	
	for(i=1;i<=nclusters;i++) 
	{
		// Sets dofile
                fname = "__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
		if (fileexists(fname)) unlink(fname)
		output_fh = fopen("__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do", "w", 1)
		
		// Step 1
		fput(output_fh, "capture {")
		fput(output_fh, "clear")
		if (c("MP")) fput(output_fh, "set processors "+strofreal(processors))
		fput(output_fh, `"cd ""'+folder+`"""')
			
		fput(output_fh, "set seed "+seeds[i])

		/* Parallel macros to be used by the current user */
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
				memset     = sprintf("%9.0f",c("memory")/nclusters)
				maxvarset  = sprintf("%g",c("maxvar"))
				matsizeset = sprintf("%g",c("matsize"))

				// Writing data limits
				if (!c("MP")) fput(output_fh, "set memory "+memset+"b")
				fput(output_fh, "set maxvar "+maxvarset)
				fput(output_fh, "set matsize "+matsizeset)
			}
		}
		/* Checking data setting is just fine */
		fput(output_fh, "}")
		fput(output_fh, "local result = _rc")
		fput(output_fh, "if (c(rc)) {")
		fput(output_fh, `"cd ""'+folder+`"""')
		fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"/__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while setting memory")"')
		fput(output_fh, "clear")
		fput(output_fh, "exit")
		fput(output_fh, "}")
		
		// Loading programs
		if (progsave)
		{
			fput(output_fh, sprintf("\n/* Loading Programs */"))
			fput(output_fh, "capture {")
			fput(output_fh, "run "+folder+"/__pll"+parallelid+"_prog.do")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"/__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading programs")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key 
		fput(output_fh, sprintf("\n/* Checking for break */"))
		fput(output_fh, "mata: parallel_break()") */
		
		// Mata objects loading
		if (matasave)
		{
			fput(output_fh, sprintf("\n/* Loading Mata Objects */"))
			fput(output_fh, "capture {")
			fput(output_fh, "mata: mata matuse "+folder+"/__pll"+parallelid+"_mata.mmat")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"/__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading mata objects")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n/* Checking for break */"))
		fput(output_fh, "mata: parallel_break()")
		
		// Globals loading
		if (getmacros)
		{
			fput(output_fh, sprintf("\n/* Loading Globals */"))
			fput(output_fh, "capture {")
			fput(output_fh, "cap run "+folder+"/__pll"+parallelid+"_glob.do")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"/__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading globals")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n/* Checking for break */"))
		fput(output_fh, "mata: parallel_break()")
				
		// Step 2		
		fput(output_fh, "capture {")
		fput(output_fh, "noisily {")
		
		// If it is not a command, i.e. a dofile
		if (!nodata) fput(output_fh, "use "+folder+"/__pll"+parallelid+"_dataset if _"+parallelid+"cut == "+strofreal(i))
		
		/* Checking for break key */
		fput(output_fh, sprintf("\n/* Checking for break */"))
		fput(output_fh, "mata: parallel_break()")
		
		if (!prefix) {
			input_fh = fopen(inputname, "r", 1)
			
			while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, line)	
			fclose(input_fh)
		} // if it is a command
		else fput(output_fh, inputname)
		
		fput(output_fh, "}")
		fput(output_fh, "}")
		if (!nodata) fput(output_fh, "save "+folder+"/__pll"+parallelid+"_dta"+strofreal(i,"%04.0f")+", replace")
		
		// Step 3
		fput(output_fh, `"cd ""'+folder+`"""')
		fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"/__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while running the command/dofile")"')
		fclose(output_fh)
	}
	return(0)
}
end

