*! version 0.1 09sep2021
*! A replacement for -shell- that works on all platforms + modes. 
*! Shell doesn't normally work in batch-mode on Windows, so in that case use plugin -procexecw-.
*! Like shell, it runs command and then waits.
program bshell
	if "`c(os)'"=="Windows" & "`c(mode)'"=="batch" {
		procexecw `0'
	}
	else {
		shell `0'
	}
end
