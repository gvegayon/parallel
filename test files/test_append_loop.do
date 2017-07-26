*! auth: Philippe Ruh
*! Version 0.14.7.23 23jul2014 @ 21:57:05
cap log close parallelnumlist
cap log close _all
log using parallelnumlist.log, replace
clear all
set more off
*set trace off

tempname f0 f1 f2

/* generating rand dataset */
set seed 123
set obs 10000
gen n = runiform()
gen x = int(_n/50)
gen str = round(runiform())
gen ab = int((3)*runiform())
gen cd = round(runiform())
save `f0', replace

parallel setclusters 4, force hostnames(`: env PLL_TEST_NODES')

/*

"foreach a of numlist 0 1 2 {" --> parallel append fails with numlist - stata somehow generates a global containing the numlist. I think this causes the trouble.

"forvalues a = 0/2 {" --> works well

*/

foreach a of numlist 0 1 2 {
	global a = `a'
	forvalues b = 0/1 {
		global b = `b'
		
		count
		if r(N)==0 {
			di in red "ERROR"
			continue, break
		}
		
		noi di "a: " $a " , b: " $b
		
		* restrict data set
		use `f0', clear
		keep if ab==$a & str==$b
		* save files for parallel append
		preserve
		keep if cd==0
		save `f1', replace
		restore
		keep if cd==1
		save `f2', replace
		
		* run parallel append
		sort x
		*parallel, by(x): by x: egen tot=total(n)
		*set trace on
		parallel append `f1' `f2', do (egen tot=total(n))
		*set trace off
		*macro dir
	} // b
} // a

erase `f0'.dta 
erase `f1'.dta 
erase `f2'.dta

log close
