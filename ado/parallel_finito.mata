*! version 1.16.9000 17may2016
*! author: George G. Vega Yon

/**oxygen
 * @brief Waits until every process finishes or stops the processes
 * @param parallelid Parallel instance id.
 * @param nchildren Number of child processes.
 * @param timeout Time (in secs) before abort.
 * @returns Number of child processes that stopped with error.
 */
mata:
//File syncing across child processes can be slow so use this to help sync
//tested on NFS
//If your cluster is different, overload this function (same name and earlier in the mlib search path).
void parallel_net_sync(string scalar fname, string scalar hostname){
	//ignore error about unused fname and hostname - this is just an example. overriding functions may use these
	
	//trying to fopen/close the file doesn't work
	//best bet is to restat the folder
	
	string matrix dummy
	stata("sleep 100")
	dummy = dir(".","files","__pll*")
	//ignore error about dummy being set but not used. It is there to suppress the output from dir() (we don't care about results)
}


real scalar parallel_finito(
	string scalar parallelid,
	| real scalar nchildren,
	real scalar timeout,
	real colvector pids,
	real scalar deterministicoutput,
	string matrix hostnames,
	string scalar ssh_str
	)
	{
	
	display(sprintf("{it:Waiting for the child processes to finish...}"))
	
	// Setting default parameters
	if (nchildren == J(1,1,.)) nchildren = strtoreal(st_global("PLL_CHILDREN"))
	if (timeout == J(1,1,.)) timeout = 6000
	
	// Variable definitios
	real scalar in_fh, out_fh, time
	real scalar suberrors, i, j, errornum, retcode
	string scalar fname, fname_break, fname_j, hostname
	string scalar msg
	real scalar bk, pressed
	real rowvector pendingcl
	
	// Initial number of errors
	suberrors = 0
	
	/* Temporaly sets break key off */
	/* In windows (by now) parallel cannot use the breakkey */
	bk = setbreakintr(0)
	pressed=0
	
	/* Checking conextion timeout */
	pendingcl = J(1,0,.)
	for(i=1;i<=nchildren;i++)
	{		
		/* Building filename */
		fname = sprintf("__pll%s_do%04.0f.log", parallelid, i)
		time = 0
		while (!fileexists(fname) & ((++time)*100 < timeout) & !breakkey())
			stata("sleep 100")
			
		if (!fileexists(fname))
		{
			display(sprintf("{it:child process %04.0f} {text:has finished with a connection error -601- (timeout) ({stata search r(601):see more})...}", i))
			
			suberrors++
			st_local("pll_last_error", "601")
			continue
		}
		else pendingcl = pendingcl, i
			
		timeout = timeout - time*100
	}
	
	/* If there are as many errors as child processes, then exit */
	if (suberrors == nchildren) return(suberrors)
	
	string scalar logfilename, tmpdirname, connection_opt
	hostname=""

	while(length(pendingcl)>0)
	{
		
		// Building filename
		for (i=1;i<=nchildren;i++)
		{
			/* If this child process is ready, then continue */
			if (!any(pendingcl :== i)) continue
			
			fname = sprintf("__pll%s_finito%04.0f", parallelid, i)
			
			if (breakkey() & !pressed) 
			{ /* If the user pressed -break-, each instance will try to finish the work through parallel finito */
				/* Message */
				display(sprintf("{it:The user pressed -break-. Trying to stop the child processes...}"))
			
				/* Openning and checking for the new file */
				fname_break = sprintf("__pll%s_break", parallelid)
				if (fileexists(fname_break)) _unlink(fname_break)
				out_fh = fopen(fname_break, "w", 1)
				
				/* Writing and exit */
				fput(out_fh, "1")
				fclose(out_fh)
				
				if (pids!=J(0,1,.)) {
					for (j=1;j<=rows(pids);j++)
					{
						connection_opt=""
						if(length(hostnames)>0) hostname = hostnames[1,mod(j-1,length(hostnames))+1]
						if(length(hostnames)>0 & hostname!="localhost"){
							connection_opt = ", connection("+ssh_str+hostname+")"
						}
						stata("prockill " + strofreal(pids[j,1])+connection_opt)
						//fake as if the child stata caught the break and exited
						fname_j=sprintf("__pll%s_finito%04.0f", parallelid, j)
						if(!fileexists(fname_j)){
							parallel_write_diagnosis("1",fname_j,"while running the command/dofile")
						}
					}
				}
				pressed = 1
				
			}
			
			connection_opt=""
			if(length(hostnames)>0) hostname = hostnames[1,mod(i-1,length(hostnames))+1]
			if(length(hostnames)>0 & hostname!="localhost"){
				connection_opt = ", connection("+ssh_str+hostname+")"
			}
		
			if (fileexists(fname)) // If the file exists
			{
				/* Child process might have made file but not exited yet
				  (so still might have it open, which would cause error when we try to delete it) */
				if(rows(pids)>0){
					stata("cap procwait " + strofreal(pids[i,1])+connection_opt)
					if(c("rc")){ //not done yet
						continue; //try again later
					}
				}
				
				/* Opening the file and looking for somethign different of 0
				(which is clear) */

				/* Copying log file */
				logfilename = sprintf("%s__pll%s_do%04.0f.log", (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/"), parallelid, i)
				stata(sprintf(`"cap copy __pll%s_do%04.0f.log "%s%s", replace"', parallelid, i, c("tmpdir"),logfilename))
				/* Sometimes Stata hasn't released the file yet. Either way, don't error out  */
				if (_unlink(pwd()+logfilename)){
					errprintf("Not able to remove temp dir\n")
				}

				in_fh = fopen(fname, "r", 1)
				if ((errornum=strtoreal(fget(in_fh))))
				{
					msg = fget(in_fh)
					if (msg == J(0,0,"")) display(sprintf(`"{it:child process %04.0f} {text:Exited with error -%g- ({stata parallel viewlog %g, e(%s):view log})...}"', i, errornum, i, parallelid))
					else display(sprintf(`"{it:child process %04.0f} {text:Exited with error -%g- %s ({stata parallel viewlog %g, e(%s):view log})...}"', i, errornum, msg, i, parallelid))
					suberrors++
					st_local("pll_last_error", strofreal(errornum))
				}
				else{
					if (!deterministicoutput) display(sprintf("{it:child process %04.0f} {text:has exited without error...}", i))
				}
				fclose(in_fh)

				/* Checking tmpdir */
				tmpdirname = sprintf("%s"+ (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/") + "__pll%s_tmpdir%04.0f", c("tmpdir"),parallelid,i)
				retcode = parallel_recursively_rm(parallelid,tmpdirname,1)
				//ignore the fact that retcode isn't used.
				if (_rmdir(tmpdirname)){
					errprintf("Not able to remove temp dir\n")
				}
				
				/* Taking the finished child process out of the list */
				pendingcl = select(pendingcl, pendingcl :!= i)
				
				continue
			} /* Else just wait for it 1/10 of a second! */
			else{ //no finish file yet
				//check if the child process was killed (or stopped w/o making finish file)
				if(rows(pids)>0){
					stata("cap procwait " + strofreal(pids[i,1])+connection_opt)
					if(!c("rc")){ //not running. 
						if(length(hostnames)>0){
							parallel_net_sync(fname, hostname)
						}
						if (!fileexists(fname)){ //Recheck file because of scheduling
							//simulate a error-ed shutdown. 700 is an unlabelled Operating System error
							parallel_write_diagnosis("700",sprintf("__pll%s_finito%04.0f", parallelid, i),"while running the command/dofile")
							// It'll be picked up next time around.
							continue 
						}
					}
				}
				stata("sleep 100")
			}
		}
	}
	
	/* Returing to old break value */
	if (querybreakintr()!=bk) 
	{
		breakkeyreset()
		(void) setbreakintr(bk)
	}
	
	real scalar linesize
	linesize = c("linesize") > 80 ? 80 : c("linesize")
	display(sprintf("{hline %g}{break}{text:Enter -{stata parallel printlog 1, e(%s):parallel printlog #}- to checkout logfiles.}{break}{hline %g}", linesize, parallelid, linesize))
	
	return(suberrors)
	
}
end

