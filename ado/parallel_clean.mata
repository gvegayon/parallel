*! vers 0.14.3 18mar2014
*! author: George G. Vega

mata:

/**
 * @brief Removes tmpfolders
 * @param parallelid Id of the paralallel process
 */
void function parallel_clean_tmp(
	|string scalar parallelid,
	real scalar force
)
{
	/* Getting the temppath */
	string scalar tmpdirs, dirslist
	string colvector sbfiles
	real scalar i
	
	string scalar tmpbat
	real scalar fh
	
	tmpdirs = dir(c("tmpdir"),"dirs","__pll"+ (parallelid == "" ? "" : parallelid)+"*" , 1)
	
	/* Getting the list of folders that should not be removed */
	sbfiles = J(0,1,"")
	if (!force)
	{
		parallel_sandbox(4,"",&sbfiles)
		for(i=1;i<=length(sbfiles);i++)
			tmpdirs = select(tmpdirs, tmpdirs :!= sbfiles[i])
	}
	
	/* If no dir left, continue */
	if (!length(tmpdirs)) return
	
	/* Removing the dirs */
	if (c("os") == "Windows")
	{
		/* Getting a file name for the tmp.bat */
		while(fileexists(tmpbat = regexr(tmpfilename(),"\.tmp$",".bat")) )
			continue

		fh = fopen(tmpbat, "w")
		
		for(i=1;i<=length(tmpdirs);i++)
		{
			tmpdirs[i] = subinstr(tmpdirs[i],"/","\",.)
			fput(fh, "rmdir /s /q "+tmpdirs[i])
		}
		fclose(fh)
		stata("shell "+tmpbat+"&erase /f "+tmpbat+"&exit")
		
	}
	else 
	{
		for(i=1;i<=length(tmpdirs);i++)
			stata("cap shell rm -R "+tmpdirs[i])
	}
	
	return
}

/**
* @brief Removes parallel auxiliry files
* @param parallelid Parallel of the id instance.
* @param cleanall Whether to remove all files no matter what parallel id.
* @param force Forces parallel to remove files even if sandbox is working.
* @returns Removes all auxiliary files.
*/
void parallel_clean(|string scalar parallelid, real scalar cleanall, real scalar force) {
	
	real scalar i ;
	string colvector files, sbfiles;
	
	// Checking arguments
	if (parallelid == J(1,1,"")) parallelid = st_global("LAST_PLL_ID");
	if (cleanall == J(1,1,.)) cleanall = 0;
	if (force==J(1,1,.)) force = 0;
	
	if (!cleanall & strlen(parallelid)) // If its not all
	{ 
		files = dir(pwd(),"files","__pll"+parallelid+"_*",1) \ dir(pwd(),"files","l__pll"+parallelid+"_*",1) \ dir(c("tmpdir"),"files","__pll"+parallelid+"sandbox",1)
	}
	else if (cleanall)
	{           // If its all
		files = dir(pwd(),"files","__pll*",1) \ dir(pwd(),"files","l__pll*",1)\dir(c("tmpdir"),"files","__pll*sandbox",1)
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
	
	/* Removing temp files */
	parallel_clean_tmp(parallelid, force)
	
	return
}
end

