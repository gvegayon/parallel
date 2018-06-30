prog def BOOTTEST
	// Loading data for boot
	quietly {
		sysuse auto, clear
		expand 10
	}
	if ($INPLL == 1) {
		qui parallel bs, rep($size) nodots: regress mpg weight gear foreign
	}
	else if ($INPLL == 0) {
		bs, rep($size) nodots: regress mpg weight gear foreign
	} 
	else {
		error 1
	}
end
