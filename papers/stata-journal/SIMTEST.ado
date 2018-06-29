prog def SIMTEST

	if ($INPLL == 1) {
		parallel sim, reps($size) expr(beta=r(beta)) nodots: mysim
	}
	else if ($INPLL == 0) {
		simulate beta=r(beta), reps($size) nodots: mysim
	}
	else {
		error 1
	}
end
