prog def mysim, rclass
	drop _all
	set obs 1000
	
	gen eps = rnormal()
	gen X   = rnormal()
	gen Y   = X*2 + eps
	
	reg Y X
	
	mat def ans = e(b)
	return scalar beta = ans[1,1]
end
