*! vers 1.14.2 25feb2014
clear all
program drop _all
run parallel_montecarlo.mata

program def parallel_resample, rclass

	syntax =/exp  [if] [in] [, Weight(varname numeric min=0)]
	//local exp `0'

	// Picking the subset
	tempvar samp
	qui gen `samp' = .

	// Getting the sample from mata
	#delim ;
	if ("`weight'"=="") 
		mata : st_store(.,"`samp'",parallel_resample(`exp'));
	else
		mata : st_store(
			.,
			"`samp'",
			parallel_resample(`exp', st_data(.,"`weight'")));
	#delim cr

	// Drawning the sample
	cap drop if `samp' == 0
	cap expand `samp'
end

sysuse auto, clear

expand 1000

set trace off

gen w = _n

timer on 1
parallel_resample 100, w(w)
timer off 1
timer on 2
bsample 100, weights(w)
timer off 2
timer list

summ

