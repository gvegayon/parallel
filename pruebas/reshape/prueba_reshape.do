clear all
timer clear
set more off
set trace off

set mem 1g

if "$S_OS" == "Windows" cap cd I:\george\comandos_paquetes_librerias\stata\parallel\pruebas\reshape
else cap cd /users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/pruebas/reshape

if "$S_OS" == "Windows" use solicitudes_parallel
else {
	use "/users/estudios/shared_bd/bases/bdsc/bases_stata/2013_04/solicitudes.dta"

	nsplit fecsolic, d(4 2 2) g(agno mes dia)

	keep if agno >= 2006

	bysort numcue agno mes: keep if _n == _N

	gen tiempo = agno*12 + mes

	xtset numcue tiempo

	keep numcue tiempo tipsolic rutemp opta derecho ngiros
}

tempfile archivo
save `archivo'

sort numcue tiempo

// run ../../ado/parallel.ado
parallel clean, all
run ../../../tabular.do

if "$S_OS" == "Windows" local tries 2 4
else local tries 2 4 8 
foreach val in `tries' { 
	parallel setclusters `val', f

	local rep = 0
	if "$S_OS" == "Windows" local sizes 100000 1000000 2000000
	else local sizes 100000 1000000 5000000
	foreach size in `sizes' {
		
		timer clear
		
		use `archivo' in 1/`size', clear

		timer on 1
		reshape wide tipsolic rutemp opta derecho ngiros, i(numcue) j(tiempo)
		timer off 1
		
		timer list 
		// CPU
		local t1 = `r(t1)'/`r(nt1)'

		use `archivo' in 1/`size', clear

		parallel, by(numcue) keepl force noglo :reshape wide tipsolic rutemp opta derecho ngiros, i(numcue) j(tiempo)

		//!less __pll`r(pll_id)'do1.do
		timer list
		
		// Parallel
		local t2 = `r(pll_t_calc)'
		
		// Setup
		local t3 = `r(pll_t_setu)'
		
		// Total
		local total = `r(pll_t_calc)' + `r(pll_t_setu)' + `r(pll_t_fini)'
		
		local better = `t1'/ `r(pll_t_calc)'
		local bettertot = `t1'/`total'
		if (!`rep++') {
			mat def tiemposreshape = `t1' \ `total' \ `r(pll_t_setu)' \ `r(pll_t_calc)' \ `r(pll_t_fini)' \ `better' \ `bettertot'
		}
		else {
			mat def tiemposreshape = tiemposreshape, (`t1' \ `total' \ `r(pll_t_setu)' \ `r(pll_t_calc)' \ `r(pll_t_fini)' \ `better' \ `bettertot')
		}
		

	}


	if "$S_OS" == "Windows" local machine Windows Machine
	else local machine Linux Server
	
	tabular tiemposreshape using tiempos_reshape_$S_OS`'$PLL_CLUSTERS.tex, replace ///
			rowname("CPU" "Total" "\hspace{2mm} Setup" "\hspace{2mm} Compute" "\hspace{2mm} Finish" "\hline Ratio (compute)" "Ratio (total)") ///
			colname(`sizes') ///
			caption(Reshaping wide a large database on a `machine' (`val' clusters)) pos(!h)
}

parallel clean, all
