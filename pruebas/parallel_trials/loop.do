// Serial replacing

// Testing objects
mata:myhelloworld()
mata: x :+ 2

helloworld

forval i=1/`=c(N)' {
	qui replace x = 1/sqrt(2*`c(pi)')*exp(-(x^2/2))*cos(x^2/2*`c(pi)')*sin(2*x*`c(pi)') in `i'
}
