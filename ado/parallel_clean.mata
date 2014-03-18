*! vers 0.14.3 18mar2014
*! author: George G. Vega

/**oxygen
* @brief Removes parallel auxiliry files
* @param parallelid Parallel of the id instance.
* @param cleanall Whether to remove all files no matter what parallel id.
* @param force Forces parallel to remove files even if sandbox is working.
* @returns Removes all auxiliary files.
*/

mata:
void parallel_clean(|string scalar parallelid, real scalar cleanall, real scalar force) {
	
	real scalar i ;
	string colvector files, sbfiles;
	
	// Checking arguments
	if (parallelid == J(1,1,"")) parallelid = st_global("r(pll_id)");
	if (cleanall == J(1,1,.)) cleanall = 0;
	if (force==J(1,1,.)) force = 0;
	
	if (!cleanall & strlen(parallelid)) // If its not all
	{ 
		files = dir("","files","__pll"+parallelid+"_*") \ dir("","files","l__pll"+parallelid+"_*")
	}
	else if (cleanall)
	{           // If its all
		files = dir("","files","__pll*") \ dir("","files","l__pll*")
	}
	
	/* Extracting files that are in use */
	if (!force) parallel_sandbox(1,"",&sbfiles)
			
	/* Checking if there is anything to clean */
	if (files == J(0,1,"")) display(sprintf("{text:parallel clean:} {result: nothing to clean...}"))
	else {
		/* Checking sandbox files */
		for(i=1;i<=length(sbfiles);i++)
			files = select(files, files:!=sbfiles[i])
	
		/* Looping over file names */
		for(i=1;i<=rows(files);i++)
			unlink(files[i])
	}
}
end

