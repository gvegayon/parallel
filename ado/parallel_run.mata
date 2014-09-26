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
	string scalar tmpdir_i
	
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

	string scalar tmpdir
	tmpdir = c("tmpdir") + (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/")
	
	if (c("os") != "Windows") { // MACOS/UNIX
		unlink("__pll"+parallelid+"_shell.sh")
		fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)

		// Writing file
		if (c("os") != "Unix") {
			for(i=1;i<=nclusters;i++) {
				mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
				fput(fh, "export TMPDIR="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f"))
				fput(fh, paralleldir+`" -e -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
			}
		}
		else {
			for(i=1;i<=nclusters;i++) {
				mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1) // fput(fh, "mkdir "+c("tmpdir")+"/__pll"+parallelid+strofreal(i,"%04.0f"))
				fput(fh, "export TMPDIR="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f"))
				fput(fh, paralleldir+`" -b -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
			}
		}

		fclose(fh)
		
		// stata("shell sh __pll"+parallelid+"shell.sh&")
		stata("winexec sh __pll"+parallelid+"_shell.sh")
	}
	else { // WINDOWS
		if (c("mode")=="batch"){ //Execute commands via Cygwin process
			if (gateway_fname == J(1,1,"")) gateway_fname = st_global("PLL_GATEWAY_FNAME")
			fh = fopen(gateway_fname,"a", 1)
			for(i=1;i<=nclusters;i++) {
				tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
				mkdir(tmpdir_i,1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
				fput(fh, `"export TEMP=""'+tmpdir_i+`"""')
				fput(fh, paralleldir+`" -e -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
			}
			fclose(fh)
		}
		else{
			unlink("__pll"+parallelid+"_shell.bat")
			fh = fopen("__pll"+parallelid+"_shell.bat","w", 1)
			
			// Writing file
			for(i=1;i<=nclusters;i++) {
				mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1)
				fwrite(fh, "start /MIN /HIGH set TEMP="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f")+" ^& ")
				fput(fh, paralleldir+`" /e /q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do"^&exit"')
			}
			
			fput(fh, "exit")
			
			fclose(fh)
			
			stata("winexec __pll"+parallelid+"_shell.bat")
		}
	}
	
	/* Waits until each process ends */
	return(parallel_finito(parallelid,nclusters,timeout))
}
end

// set TEMP=C:\Users\SPENSI~1\AppData\Local\Temp/ubslh38mmc1 & "C:\Program Files (x86)\Stata12/Stata-64.exe" /e /q do __pllubslh38mmc_do1.do

