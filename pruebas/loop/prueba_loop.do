clear all
set more off
set trace off

mata: mata set matalnum off

if "$S_OS" == "Windows" cap cd I:\george\comandos_paquetes_librerias\stata\parallel\pruebas\loop
else cap cd /users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/pruebas/loop

//run ../../ado/parallel.ado
run ../../../tabular.do

if "$S_OS" == "Windows" local tries 2 4
else local tries 2 4 8 16
foreach val in `tries' { 

	parallel setclusters `val', f

	local rep = 0
	foreach size in 100000 1000000 10000000 {
	
		clear
		timer clear
		set obs `size'

		gen x = rnormal()
			
		preserve
		
		timer on 1
		run loop_calculado
		timer off 1

		save 20120827_loop_noparalelo, replace
		restore

		preserve
		parallel do "loop_calculado.do", keepl
		restore
		
		timer list
		
		// CPU
		local t1 = `r(t1)'/`r(nt1)'
		
		// Parallel
		local t2 = `r(pll_t_calc)'
		
		// Setup
		local t3 = `r(pll_t_setu)'
		
		// Total
		local total = `r(pll_t_calc)' + `r(pll_t_setu)' + `r(pll_t_fini)'
		
		local better = `t1'/ `r(pll_t_calc)'
		local bettertot = `t1'/`total'
		
		if `++rep' == 1 {
			mat def tiemposreshape = `t1' \ `total' \ `r(pll_t_setu)' \ `r(pll_t_calc)' \ `r(pll_t_fini)' \ `better' \ `bettertot'
		}
		else {
			mat def tiemposreshape = tiemposreshape, (`t1' \ `total' \ `r(pll_t_setu)' \ `r(pll_t_calc)' \ `r(pll_t_fini)' \ `better' \ `bettertot')
		}
		
		if "$S_OS" == "Windows" local machine Windows Machine
		else local machine Linux Server
		
		tabular tiemposreshape using 20130516_tiempos_loop_$S_OS`'$PLL_CLUSTERS.tex, replace ///
				rowname("CPU" "Total" "\hspace{2mm} Setup" "\hspace{2mm} Compute" "\hspace{2mm} Finish" "\hline Ratio (compute)" "Ratio (total)") ///
				colname(10.000 100.000 1.000.000 10.000.000) ///
				caption(Serial replacing using a loop on a `machine' (`val' clusters)) pos(!h)
	}
}

parallel clean, all
