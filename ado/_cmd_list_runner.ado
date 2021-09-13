program _cmd_list_runner
	syntax [, maindata(string)]
	loc N = _N
	loc first = i[1]

	if "`maindata'"!=""{
		use "`maindata'", clear
	} 
	else {
		clear
	}
	forv i=1/`N' {
		mata: st_local("cmd", PLL_iters[1, `first'-1+`i'])
		di `"cmd: `cmd'"'
		`cmd'
	}
end
