set matadebug off
*set trace off


*clear all
program drop _all
macro drop _all
mata: mata clear
set matastrict on

parallel clean, all

sysuse auto, clear

parallel setclusters 2, force

/* Simple tests */
parallel, by(foreign) f keepl nog : egen maxp = max(price)
parallel, by(foreign) f keepl nog: egen maxp2 = max(price)
parallel, by(foreign) f keepl nog: gen n = _N

type __pll`r(pll_id)'_do0001.do

parallel clean, all

/* Testing cluster assigment */
parallel setclusters default //just to check
parallel numprocessors
parallel setclusters 2, force
sort rep78
parallel, by(rep78) f keepl nog: gen n2 = _N
parallel, by(rep78) f keepl nog: gen n3 = _N

/* Testing collapse */
tempfile original cllps1
save `"`original'"'

collapse (mean) price foreign, by(rep78)
save `"`cllps1'"'

use `"`original'"'
parallel, by(rep78) nog f:collapse (mean) price foreign, by(rep78)
cf _all using `"`cllps1'"'

parallel, nog keepl: mata: for(i=1;i<=1e6;i++) parallel_break()

parallel clean, all


