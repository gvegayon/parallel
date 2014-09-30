* Testing that scalars and matrices are copied correctly
* (along with global macros).

set matadebug off
set trace off

*clear all
program drop _all
macro drop _all
mata: mata clear

cap program drop testing_all_globals
program testing_all_globals
	scalar temps = numscalar*xmat[1,1]*`=strscalar'
	gen price2=price*temps
end


mat xmat = J(2,2,3)
scalar numscalar = 4
scalar strscalar = "6"

sysuse auto, clear


parallel clean, all
parallel setclusters 2
parallel, programs(testing_all_globals) : testing_all_globals
