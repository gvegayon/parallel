forval i = 1/50 {
	local myseed = (`pll_instance' - 1)*50 + `i'
	set seed `myseed'
	sysuse auto, clear
	sample 60, count
	tempfile myregress
	parmby "regress weight i.foreign#i.rep78", saving("result_`pll_instance'_`i'", replace) norestore
}
