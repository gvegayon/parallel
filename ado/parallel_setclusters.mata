mata:
void parallel_setclusters(real scalar nclusters, |real scalar force) {
		
	// Setting number of clusters
	if (force == J(1,1,.)) force = 0
	if (nclusters <= 8 | (nclusters > 8 & force)) {
		st_global("PLL_CLUSTERS", strofreal(nclusters))
	}
	else _error(912,`"Too many clusters: If you want to set more than 8 clusters you should use the option -force-"')
	display(sprintf("{text:N Clusters}: {result:%g}",nclusters))
}
end
