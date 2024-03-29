*! vers 0.14.7 22jul2014
*! author: George G. Vega Yon

/**oxygen
 * @brief Sets the path where stata exe is installed.
 * @param statadir If the user wants to set it manually
 * @param force Avoids path checking.
 * @returns A global PLL_STATA_PATH.
 */

mata:
string scalar parallel_default_statapath() {

	string scalar bit, flv, flv2, fname, statadir
	
	// Is it 64bits?
	if (c("osdtl") != "" | c("bit") == 64) bit = "-64"
	else bit = ""
	
	if (c("os") == "Windows") { // WINDOWS
		if (c("MP")) flv = "MP"
		else if (c("SE")) flv = "SE"
		else if (c("flavor") == "Small") flv = "SM"
		else if (c("flavor") == "IC"){ 
			if (c("stata_version") <17) flv = "" 
			else flv = "BE" //Basic Edition. the new c(edition)=="BE"
		}
	
		/* If the version is less than eleven */
		if (c("stata_version") < 11) fname = "w"+flv+"Stata.exe"
		else fname = "Stata"+flv+bit+".exe"
		
		statadir = c("sysdir_stata") + fname
		
	}
	else if (regexm(c("machine_type"), "^Mac.*")) { // MACOS. (Note, c(os) for Mac in CLI actuall reports "Unix")
	
		if (c("stata_version") < 11 & (c("osdtl") != "" | c("bit") == 64)) bit = "64"
		else bit = ""
		//not sure if the flv2 variants use bit, but we don't support those old ones.
		if (c("MP")){
			flv = "Stata"+bit+"MP" 
			flv2 = "stata"+bit+"-mp" 
		}
		else if (c("SE")) {
			flv = "Stata"+bit+"SE"
			flv2 = "stata"+bit+"-se"
		}
		else if (c("flavor") == "Small"){
			flv = "smStata"
			flv2 = "stata-sm" //not sure about this one
		}
		else if (c("flavor") == "IC"){
			if (c("stata_version") <17){
				flv = "Stata"+bit
				flv2 = "stata"+bit
			}
			else {
				flv = "StataBE" //Basic Edition. the new c(edition)=="BE"
				flv2 = "stata-be"+bit //this is a guess
			}
		}
		
		//use flv at end for gui. Use flv2 for cmd-line
		statadir = c("sysdir_stata")+flv+".app/Contents/MacOS/"+flv2
	}
	else { // UNIX
		if (c("MP")) flv = "stata-mp" 
		else if (c("SE")) flv = "stata-se"
		else if (c("flavor") == "Small") flv = "stata-sm"
		else if (c("flavor") == "IC") flv = "stata"
	
		statadir = c("sysdir_stata")+flv
	}
	return(statadir)
}

real scalar parallel_setstatapath(string scalar statadir, | real scalar force) {
	string scalar fname
	// Building fullpath name
	if (statadir == J(1,1,"") | statadir == "") {
		statadir = parallel_default_statapath()
		
		//might need to convert to cygwin path-name
		if (c("os") == "Windows" & c("mode")=="batch" & st_global("USE_PROCEXEC")=="0"){
			if (!force) if (!fileexists(statadir)) return(601)
			fname = substr(statadir, strlen(c("sysdir_stata"))+1, strlen(statadir) - strlen(c("sysdir_stata")))
			statadir = "/cygdrive/"+substr(c("sysdir_stata"),1,1)+"/"+substr(c("sysdir_stata"),4,.) + fname
			force=1
		}
	}

	// Setting PLL_STATA_PATH
	if (force == J(1,1,.)) force = 0
	if (!force) if (!fileexists(statadir)) return(601)
	
	if (!regexm(statadir, `"^["]"')) st_global("PLL_STATA_PATH", `"""'+statadir+`"""')
	else st_global("PLL_STATA_PATH", statadir)
	
	display(sprintf("{text:Stata dir:} {result: %s}" ,statadir))
	return(0)
}
end

