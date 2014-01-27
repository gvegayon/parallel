clear all
parallel setclusters 2
parallel do 1upto50_regressions.do, nodata noglobal keepl

use result_1_1, clear
gen regid = 1

local nid = 0
forval j = 1/2 {
	forval i = 1/50 {
		if `++nid' != 1 {
			append using result_`j'_`i'
			replace regid = `nid' if regid == .
		}
	}
}

tab regid
