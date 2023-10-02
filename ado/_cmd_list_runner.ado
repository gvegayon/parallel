program _cmd_list_runner
	syntax [, maindata(string)]
	loc N = _N

	forv i=1/`N' {	
		preserve
		loc cmd_i = i[`i']
		if "`maindata'"!=""{
			use "`maindata'", clear
		} 
		else {
			clear
		}
		mata: st_local("cmd", PLL_iters[1, `cmd_i'])
		di `"cmd: `cmd'"'
		`cmd'
		restore
	}
end
