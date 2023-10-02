*! version 0.2 25sep2023
*! A way to record commands and then run them all either in parallel or sequentially. 
program cmd_list
    gettoken sub_cmd 0 : 0, parse(" :,")

    _assert inlist("`sub_cmd'", "clear", "add", "run", "view"), msg("-cmd_list sub_cmd-: `sub_cmd' not found (should be clear, add, view, or run).")
    if "`sub_cmd'"=="clear" {
		mata: rmexternal("PLL_iters")
        *mata: PLL_iters = J(1,0,"")
    }
    if "`sub_cmd'"=="add" {
        _on_colon_parse `0'
        loc cmd `s(after)'
        mata: st_local("PLL_iters_len", strofreal(length(direxternal("PLL_iters"))))
        if `PLL_iters_len'==0{
            mata: PLL_iters = J(1,0,"")
        } 
        mata: PLL_iters = (PLL_iters, st_local("cmd"))
    }
    if "`sub_cmd'"=="run"{
        syntax [, parallel nocleanup mata *]
        
        mata: st_local("n_iters", strofreal(length(PLL_iters)))
        
        if c(k)>0 {
            tempfile maindata
            qui save "`maindata'"
        }
        else loc maindata ""
        
        preserve
        clear
        qui set obs `n_iters'
        gen long i = _n
		if "`parallel'"!=""{
			loc parallel "parallel, mata `options':"
			* switch from [c1,c1,...,c2,c2] -> [c1,c2,...,c1,c2]
			gen long cl=mod(_n-1, $PLL_CLUSTERS)+1
			sort cl i
			drop cl
		}
        `parallel' _cmd_list_runner, maindata("`maindata'")
        restore

        if "`cleanup'"!="nocleanup" mata:  rmexternal("PLL_iters")
        if "`cleanup'"!="nocleanup" mata: if(length(direxternal("PLL_temp"))>0){rmexternal("PLL_temp");};
    }
    if "`sub_cmd'"=="view"{
        mata: st_local("PLL_iters_len", strofreal(length(direxternal("PLL_iters"))))
        if `PLL_iters_len'!=0{
            mata: PLL_iters
        }
    }
end