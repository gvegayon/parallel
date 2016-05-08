
mata

/*
 *@brief Recursively removes parallel tmpfiles
 *@param parallelid Id of the parallel process to clean
 *@param path Path where to search for auxiliary files
 */
real scalar function parallel_recursively_rm(string scalar parallelid ,| string scalar path, real scalar atomic, real scalar rmlogs)
{
	if (path==J(1,1,"")) path = pwd()
	else if (!regexm(path,"[/\]$")) path = path+"/"

	// display("{hline}{break}Entering folder "+path)
	
	if (atomic == J(1,1,.)) atomic = 0
	if (rmlogs == J(1,1,.)) rmlogs = 0
	
	string scalar pattern
	if (!atomic) pattern = "__pll"+parallelid+"_*"
	else pattern = "*"

	string colvector dirs
	string colvector files

	/* Listing files */
	dirs  = dir(path,"dirs",pattern,1)
	files = dir(path,"files",pattern,1)\dir(path,"files","l"+pattern,1)
	
	real scalar i, retcode
	retcode=0
	if (atomic)
	{
		for(i=1;i<=length(files);i++){
			if (_unlink(files[i])){
				stata("sleep 2000")
				if(_unlink(files[i])){
					retcode=1
				}
			}
		}
	}
	else
	{
		/* We don't want to remove logfiles in tmpdir */
		for(i=1;i<=length(files);i++)
			if ( !regexm(files[i],"do[0-9]+\.log$") | rmlogs){
				if (_unlink(files[i])){
					stata("sleep 2000")
					if(_unlink(files[i])){
						retcode=1
					}
				}
			}
	}

	/* Entering each folder */
	for(i=1;i<=length(dirs);i++){
		if(parallel_recursively_rm(parallelid, dirs[i], 1))
			retcode=1
	}

	/* Removing empty folders */
	for(i=1;i<=length(dirs);i++){
		if (_rmdir(dirs[i])){
			stata("sleep 2000")
			if(_rmdir(dirs[i])){
				retcode=1
			}
		}
	}


	return(retcode)
}

end
