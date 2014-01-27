local maxn = _N
forval i = 1/`maxn' {
	qui replace x = 1/sqrt(2*`c(pi)')*exp(-(x^2)/(2)) in `i'
}
