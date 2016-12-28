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

	real scalar fh, i, use_procexec, folder_has_space
	string scalar tmpdir, tmpdir_i, line, line2, dofile_i, dofile_i_base, pidfile, stata_quiet, stata_batch, folder, exec_cmd, dofile_i_basename
	real colvector pids
	pids = J(0,1,.)
	
	// Setting default parameters
	if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
	if (paralleldir == J(1,1,"")) paralleldir = st_global("PLL_STATA_PATH")
	
	// Message
	display(sprintf("{hline %g}",c("linesize") > 80?80:c("linesize")))
	display("{result:Parallel Computing with Stata}")
	display("{text:Clusters   :} {result:"+strofreal(nclusters)+"}")
	display("{text:pll_id     :} {result:"+parallelid+"}")
	display("{text:Running at :} {result:"+c("pwd")+"}")
	display("{text:Randtype   :} {result:"+st_local("randtype")+"}")

	tmpdir = c("tmpdir") + (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/")
	//If there is a -cd- command in (sys)profile.do then we need to 
	// specify the full path for the do file.  so grab the directory
	folder = st_global("LAST_PLL_DIR")
	folder_has_space = (length(tokens(folder))>1)
	
	if (c("os") != "Windows") { // MACOS/UNIX
		unlink("__pll"+parallelid+"_shell.sh")
		fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)
		pidfile = "__pll"+parallelid+"_pids"
		unlink(pidfile)
		stata_quiet = " -q"
		stata_batch = (c("os") == "Unix" ?" -b":" -e")
		// Writing file
		for(i=1;i<=nclusters;i++) {
			tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
			mkdir(tmpdir_i,1) 
			fput(fh, "export STATATMP="+tmpdir_i)
			dofile_i_base = "__pll"+parallelid+"_do"+strofreal(i,"%04.0f")
			dofile_i = folder+dofile_i_base+".do"
			//The standard batch-mode way of calling funbles the automated name of the log file
			// if the folder has a space in it (it makes it the first word before the space,
			// rather than the base). So do the < > redirect way.
			//exec_cmd = paralleldir+stata_batch+stata_quiet+" "+`"do \""'+dofile_i + `"\""'
			exec_cmd = paralleldir+stata_quiet+ `" < ""'+dofile_i + `"" > "' + dofile_i_base + ".log"
			fput(fh, exec_cmd + " & echo $! >> "+pidfile)
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
		use_procexec = strtoreal(st_global("USE_PROCEXEC"))
		if (!use_procexec){
			if (c("mode")=="batch"){ //Execute commands via Cygwin process
				if (gateway_fname == J(1,1,"")) gateway_fname = st_global("PLL_GATEWAY_FNAME")
				fh = fopen(gateway_fname,"a", 1)
				for(i=1;i<=nclusters;i++) {
					tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
					mkdir(tmpdir_i,1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
					fput(fh, `"export STATATMP=""'+tmpdir_i+`"""')
					dofile_i = folder+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
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
					dofile_i = folder+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
					fput(fh, paralleldir+`" /e /q do ""'+dofile_i+`""^&exit"')
				}
				
				fput(fh, "popd")
				fput(fh, "exit")
				
				fclose(fh)
				
				stata("winexec __pll"+parallelid+"_shell.bat")
			}
		}
		else{
			st_numscalar("PROCEXEC_HIDDEN",use_procexec)
			st_numscalar("PROCEXEC_ABOVE_NORMAL_PRIORITY",1)

			for(i=1;i<=nclusters;i++) {
				tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f")
				mkdir(tmpdir_i,1)
				dofile_i = folder+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
				line2 = paralleldir+`" /e /q do ""'+dofile_i+`"""'
				stata("procenv set STATATMP="+tmpdir_i)
				stata("procexec "+line2)
				pids = pids\st_numscalar("r(pid)")
			}
			stata("procenv set STATATMP="+tmpdir)
		}
	}
	
	/* Waits until each process ends */
	return(parallel_finito(parallelid,nclusters,timeout,pids))
}
end


