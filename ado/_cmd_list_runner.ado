program _cmd_list_runner
	syntax [, maindata(string)]
	loc N = _N
	loc first = i[1]

	forv i=1/`N' {		
		if "`maindata'"!=""{
			use "`maindata'", clear
		} 
		else {
			clear
		}
		mata: st_local("cmd", PLL_iters[1, `first'-1+`i'])
		di `"cmd: `cmd'"'
		`cmd'
	}
end
