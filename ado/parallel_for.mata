cap mata: mata drop parallel_for()
mata:
void parallel_for(real matrix data, string scalar fun, | real scalar byrow) {
	
	real scalar i, obsleft, clsize, nobs
	real rowvector sizes
	
	// Setting how many obs should be
	if (byrow == J(1,1,.)) byrow = 1
	
	if (byrow) nobs = rows(data)
	else nobs = cols(data)
	
	clsize  = round(nobs/4)
	obsleft = nobs
	sizes = J(1,0,.)
	while ((obsleft = (obsleft - clsize)) > 0) {
		sizes = sizes, clsize
	}
	
	if ((obsleft = nobs - sum(sizes)) > 0) sizes = sizes, obsleft
	
	fun = sprintf("mata:\nfor(i=1;i<=%g;i++) {\n\t%s\n}\nend",rows(data), fun)
	parallel_write_do(fun, "123123", 4)
}
end

parallel clean, all
mata: parallel_for(J(50,2,1),"sum[1..i]")
