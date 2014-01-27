program define mcsimul1, rclass
	version 10.0
	syntax [, c(real 1)]
	
	tempvar e1 e2
	gen double `e1'=invnorm(uniform())*`c'*zmu
	gen double `e2'=invnorm(uniform())*`c'*z_factor
	
	replace y1 = true_y + `e1'
	replace y2 = true_y + `e2'
	
	summ y1
	return scalar mu1 = r(mean)
	return scalar se_mu1 = r(sd)/sqrt(r(N))
	
	summ y2
	return scalar mu2 = r(mean)
	return scalar se_mu2 = r(sd)/sqrt(r(N))
	
	return scalar c = `c'
end
