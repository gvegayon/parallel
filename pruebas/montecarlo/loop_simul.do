local num_of_intervals = 50
if length("`pll_id'") == 0 {
	local start = 1
	local end = `num_of_intervals'
}
else {
	local ntot = floor(`num_of_intervals'/$PLL_CLUSTERS)
	local start = (`pll_instance' - 1)*`ntot' + 1
	local end = (`pll_instance')*`ntot'
	if `pll_instance' == $PLL_CLUSTERS local end = 10
}

local reps 10000
forval i=`start'/`end' {
	qui use census2, clear
	gen true_y = age
	gen z_factor = region
	sum z_factor, meanonly
	scalar zmu = r(mean)
	qui {
		gen y1 = .
		gen y2 = .
		local c = `i'
		set seed `c'
		simulate c=r(c) mu1=r(mu1) se_mu1 = r(se_mu1) ///
				mu2=r(mu2) se_mu2 = r(se_mu2), /// 
				saving(cc`i', replace) nodots reps(`reps'): ///
				mcsimul1, c(`c')
	}
}
