*! version 0.1 13sep2021
*! A way to record commands and then run them all either in parallel or sequentially. 
program cmd_list
    gettoken sub_cmd 0 : 0, parse(" :,")

    _assert inlist("`sub_cmd'", "clear", "add", "run"), msg("-cmd_list sub_cmd-: `sub_cmd' not found (should be clear, add, or run).")
    if "`sub_cmd'"=="clear" {
		mata: rmexternal("PLL_iters")
        *mata: PLL_iters = J(1,0,"")
    }
    if "`sub_cmd'"=="add" {
        _on_colon_parse `0'
        loc cmd `s(after)'
		* these two lines were tricky to get right on several versions of Stata
        mata: if(length(direxternal("PLL_iters"))==0) {PLL_temp = crexternal("PLL_iters");};
		mata: if(PLL_iters==J(0,0,.)){PLL_iters = J(1,0,"");};
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
        
        if "`parallel'"!="" loc parallel "parallel, mata `options':"
        preserve
        clear
        qui set obs `n_iters'
        gen long i = _n
        `parallel' _cmd_list_runner, maindata("`maindata'")
        restore

        if "`rm'"!="nocleanup" mata:  rmexternal("PLL_iters")
        if "`rm'"!="nocleanup" mata: if(length(direxternal("PLL_temp"))>0){rmexternal("PLL_temp");};
    }
end