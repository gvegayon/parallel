*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon

/**oxygen
 * @brief Initial child process setup for parallel.
 * @param nchildren Number of child processes.
 * @param force Whether to force setting more than nproc child processes.
 * @param nproc Number of processors on the system.
 * @returns Globals PLL_CLUSTERS (deprecated) and PLL_CHILDREN.
 */
mata:
void parallel_initialize(real scalar nchildren, |real scalar force, real scalar nproc) {
		
	// Setting number of child processes
	if (force == J(1,1,.)) force = 0
	if (nproc==. | nchildren <= nproc | force) {
		st_global("PLL_CLUSTERS", strofreal(nchildren))
		st_global("PLL_CHILDREN", strofreal(nchildren))
	}
	else _error(912,`"Use -force- if you want to set more child processes than there are processors."')
	display(sprintf("{text:N Child processes}: {result:%g}",nchildren))
}
end
