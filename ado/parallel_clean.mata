*! vers 0.14.3 18mar2014
*! author: George G. Vega

mata:

/**
* @brief Removes parallel auxiliry files
* @param parallelid Parallel of the id instance.
* @param cleanall Whether to remove all files no matter what parallel id.
* @param force Forces parallel to remove files even if sandbox is working.
* @returns Removes all auxiliary files.
*/
void parallel_clean(|string scalar parallelid, real scalar cleanall, real scalar force, real scalar logs) {
	
	real scalar i, retcode
	string colvector parallelids, sbfiles
	
	// Checking arguments
	if (parallelid == J(1,1,"")) parallelid = st_global("LAST_PLL_ID")
	if (cleanall == J(1,1,.)) cleanall = 0
	if (force==J(1,1,.)) force = 0
	if (logs==J(1,1,.)) logs = 0
	
	/* Getting the list of parallel ids that should be removed */
	if (cleanall)
	{
		parallelids = dir(pwd(),"files","__pll*") \ dir(pwd(),"files","l__pll*") \ dir(pwd(),"dirs","__pll*")

		for(i=1;i<=length(parallelids);i++)
			parallelids = regexr(regexr(parallelids,"^l?__pll",""),"_.+$","")
		parallelids = uniqrows(parallelids)
	}
	else parallelids = parallelid

	
	/* Extracting files that are in use */
	if (!force) parallel_sandbox(6,"",&sbfiles)

	for(i=1;i<=length(sbfiles);i++)
		parallelids = select(parallelids, parallelids:!=sbfiles[i])

	/* Cleaning up */
	retcode= 0
	if (length(parallelids))
	{
		for(i=1;i<=length(parallelids);i++)
		{
			if (parallel_recursively_rm(parallelids[i],pwd(),., logs))
				retcode=1
			if (parallel_recursively_rm(parallelids[i],c("tmpdir"),., logs))
				retcode=1
		}
	}
	else display(sprintf("{text:parallel clean:} {result: nothing to clean...}"))
	
	if(retcode) errprintf("Couldn't remove all files.\n")
}
end

