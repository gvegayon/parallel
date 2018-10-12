*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon

/**oxygen
 * @brief Initial cluster setup for parallel.
 * @param ncluster Number of clusters.
 * @param force Whether to force setting more than nproc clusters.
 * @param nproc Number of processors on the system.
 * @returns A global PLL_CLUSTERS.
 */
mata:
void parallel_setclusters(real scalar nclusters, |real scalar force, real scalar nproc) {
		
	// Setting number of clusters
	if (force == J(1,1,.)) force = 0
	if (nproc==. | nclusters <= nproc | force) {
		st_global("PLL_CLUSTERS", strofreal(nclusters))
	}
	else _error(912,`"Use -force- if you want to set clusters than there are processors."')
	display(sprintf("{text:N Child processes}: {result:%g}",nclusters))
}
end
