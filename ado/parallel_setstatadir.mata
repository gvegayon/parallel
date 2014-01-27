mata:
real scalar parallel_setstatadir(string scalar statadir, | real scalar force) {

	string scalar bit, flv

	// Is it 64bits?
	if (c("osdtl") != "" | c("bit") == 64) bit = "-64"
	else bit = ""
	
	// Building fullpath name
	if (statadir == J(1,1,"") | statadir == "") {
		if (c("os") == "Windows") { // WINDOWS
			if (c("MP")) flv = "MP"
			else if (c("SE")) flv = "SE"
			else if (c("flavor") == "Small") flv = "SM"
			else if (c("flavor") == "IC") flv = ""
		
			/* If the version is less than eleven */
			if (c("stata_version") < 11) statadir = c("sysdir_stata")+"w"+flv+"Stata.exe"
			else statadir = c("sysdir_stata")+"Stata"+flv+bit+".exe"
		
		}
		else if (regexm(c("os"), "^MacOS.*")) { // MACOS
		
			if (c("stata_version") < 11 & (c("osdtl") != "" | c("bit") == 64)) bit = "64"
			else bit = ""
		
			if (c("MP")) flv = "Stata"+bit+"MP" 
			else if (c("SE")) flv = "Stata"+bit+"SE"
			else if (c("flavor") == "Small") flv = "smStata"
			else if (c("flavor") == "IC") flv = "Stata"+bit
			
			statadir = c("sysdir_stata")+flv+".app/Contents/MacOS/"+flv
		}
		else { // UNIX
			if (c("MP")) flv = "stata-mp" 
			else if (c("SE")) flv = "stata-se"
			else if (c("flavor") == "Small") flv = "stata-sm"
			else if (c("flavor") == "IC") flv = "stata"
		
			statadir = c("sysdir_stata")+flv
		}
	}

	// Setting PLL_DIR
	if (force == J(1,1,.) | force == 1)	{
		if (!fileexists(statadir)) return(601)
	}
	
	if (!regexm(statadir, `"^["]"')) st_global("PLL_DIR", `"""'+statadir+`"""')
	else st_global("PLL_DIR", statadir)
	
	display(sprintf("{text:Stata dir:} {result: %s}" ,statadir))
	return(0)
}
end
