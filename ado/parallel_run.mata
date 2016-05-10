*! version 0.14.7.22 22jul2014
*! author: George G. Vega Yon

/**
 * @brief Runs parallel clusters in batch mode.
 * @param parallelid Parallel id.
 * @param nclusters Number of clusters.
 * @param paralleldir Dir where the process should be running.
 * @param timeout Number of seconds to wait until stop the process for no conextion.
 * @param gateway_fname Name of file that a Cygwin process is listen to will execute from (Windows batch).
 * @returns Number of clusters that stopped with an error.
 */

mata:
real scalar parallel_run(
	string scalar parallelid, 
	|real scalar nclusters, 
	string scalar paralleldir,
	real scalar timeout,
	string scalar gateway_fname
	) {

	real scalar fh, i
	string scalar tmpdir, tmpdir_i, line, dofile_i, pidfile, stata_opt
	real colvector pids
	pids = J(0,1,.)
	
	// Setting default parameters
	if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
	if (paralleldir == J(1,1,"")) paralleldir = st_global("PLL_STATA_PATH")
	
	// Message
	display(sprintf("{hline %g}",c("linesize") > 80?80:c("linesize")))
	display("{result:Parallel Computing with Stata} (by GVY)")
	display("{text:Clusters   :} {result:"+strofreal(nclusters)+"}")
	display("{text:pll_id     :} {result:"+parallelid+"}")
	display("{text:Running at :} {result:"+c("pwd")+"}")
	display("{text:Randtype   :} {result:"+st_local("randtype")+"}")

	tmpdir = c("tmpdir") + (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/")
	
	if (c("os") != "Windows") { // MACOS/UNIX
		unlink("__pll"+parallelid+"_shell.sh")
		fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)
		pidfile = "__pll"+parallelid+"_pids"
		unlink(pidfile)
		stata_opt = (c("os") == "Unix" ?" -b -q ":" -e -q ")
		// Writing file
		for(i=1;i<=nclusters;i++) {
			tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
			mkdir(tmpdir_i,1) 
			fput(fh, "export STATATMP="+tmpdir_i)
			dofile_i = pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
			fput(fh, paralleldir+stata_opt+`"do ""'+dofile_i+`"" & echo $! >> "'+pidfile)
		}

		fclose(fh)
		
		stata("shell sh __pll"+parallelid+"_shell.sh") //wait for the pids to be full written
		
		fh = fopen(pidfile, "r")
		while ((line=fget(fh))!=J(0,0,"")) {
			pids = pids \ strtoreal(line)
		}
		fclose(fh)
		unlink(pidfile)
	}
	else { // WINDOWS
		if (c("mode")=="batch"){ //Execute commands via Cygwin process
			if (gateway_fname == J(1,1,"")) gateway_fname = st_global("PLL_GATEWAY_FNAME")
			fh = fopen(gateway_fname,"a", 1)
			for(i=1;i<=nclusters;i++) {
				tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
				mkdir(tmpdir_i,1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
				fput(fh, `"export STATATMP=""'+tmpdir_i+`"""')
				dofile_i = pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
				fput(fh, paralleldir+`" -e -q do ""'+dofile_i+`"" &"')
			}
			fclose(fh)
		}
		else{
			unlink("__pll"+parallelid+"_shell.bat")
			fh = fopen("__pll"+parallelid+"_shell.bat","w", 1)
			
			fput(fh, "pushd "+pwd())

			// Writing file
			for(i=1;i<=nclusters;i++) {
				tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
				mkdir(tmpdir_i,1)
				fwrite(fh, "start /MIN /HIGH set STATATMP="+tmpdir_i+" ^& ")
				dofile_i = "__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
				fput(fh, paralleldir+`" /e /q do ""'+dofile_i+`""^&exit"')
			}
			
			fput(fh, "popd")
			fput(fh, "exit")
			
			fclose(fh)
			
			stata("winexec __pll"+parallelid+"_shell.bat")
		}
	}
	
	/* Waits until each process ends */
	return(parallel_finito(parallelid,nclusters,timeout))
}
end


