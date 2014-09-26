clear all
set more off
set trace off

if (c(os) == "Windows") parallel setclusters 2
else parallel setclusters 8, f

sysuse auto

local nreps 1000


forval i=1/1 {
	timer on 2
	parallel bs, sav(pllbs, replace) reps(`nreps') nodots  : reg price c.weig##c.weigh foreign rep, robust
	timer off 2

	timer on 1
	bs, reps(`nreps') nodots sav(bs, replace): reg price c.weig##c.weigh foreign rep, robust
	timer off 1
}

qui {
	use pllbs, clear
	gen pll = 1
	append using bs
	replace pll=0 if pll == .
}

bysort pll: summ

timer list

erase pllbs.dta
erase bs.dta
