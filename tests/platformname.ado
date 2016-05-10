/* not sure the values to check for these
MAC (32-bit PowerPC)
OSX.PPC (32-bit PowerPC)
SOL64, and SOLX8664 (64-bit x86-64)*/
program platformname, rclass
	args local
	* -help creturn- on Windows v14 says these are the only three options currently
	_assert(inlist("`c(os)'","Windows","Unix","MacOSX")), msg("c(OS) not recognized.")
	if "`c(os)'"=="Windows"{
		if "`c(machine_type)'"=="PC (64-bit x86-64)" loc plat "WIN64A"
		else local plat "WIN"
	}
	if "`c(os)'"=="Unix"{ //Linux x86
		if "`c(machine_type)'"=="PC (64-bit x86-64)" loc plat "LINUX64"
		else local plat "LINUX"
	}
	if "`c(os)'"=="MacOSX"{
		local plat = cond("`c(console)'"=="console","OSX.X86","MACINTEL")
		if "`c(machine_type)'"=="Macintosh (Intel 64-bit)"{
			local plat "`plat'64"
		}
	}
	if "`local'"!="" c_local `local' `plat'
	return local platformname = "`plat'"
end
