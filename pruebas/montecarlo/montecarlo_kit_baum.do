clear all
set more off

// Initial configurations
if "$S_OS" == "Windows" cap cd I:\george\comandos_paquetes_librerias\stata\parallel\pruebas\montecarlo
else cap cd /users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/pruebas/montecarlo
//run ../../ado/parallel.ado
run ../../../tabular.do

!rm cc*.dta


local rep = 0
if "$S_OS" == "Windows" local tries 2 4
else local tries 2 4 8 16
foreach val in `tries' { 
	timer clear

	// Serial simulation
	timer on 1
	do loop_simul.do
	timer off 1
	
	use cc1, clear
	forval i=2/10 {
		append using cc`i'
	}
	gen het_infl = se_mu2/se_mu1
	save cc_1_10_no_pll, replace

	// Parallel simulation
	parallel setclusters `val', force
	forval i = 1/10 {
		!rm cc`i'.dta
	}
	
	parallel do loop_simul.do, nodata keepl
	
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
	
	tabular tiemposreshape using 20130516_tiempos_montecarlo_paper_$S_OS`'.tex, replace ///
			rowname("CPU" "Total" "\hspace{2mm} Setup" "\hspace{2mm} Compute" "\hspace{2mm} Finish" "\hline Ratio (compute)" "Ratio (total)") ///
			colname(`tries') ///
			caption(Monte Carlo Experiment on a `machine' (`val' clusters)) pos(!h)	
}

use cc1, clear
forval i=2/10 {
	append using cc`i'
}
gen het_infl = se_mu2/se_mu1
save cc_1_10_pll, replace

// Tagging results
gen pll = 1

append using cc_1_10_no_pll

replace pll = 0 if pll == .

// Testing if there are significant diferences between simulations
foreach val of varlist mu* se_mu* {
	di "`val'"
	ttest `val', by(pll)
}

sort pll
by pll:tabstat mu1 se_mu1 mu2 se_mu2 het_infl, ///
	stat(mean) by(c)

by pll:tabstat het_infl, stat(mean q iqr) by(c)

parallel clean, all

use cc_1_10_no_pll, clear
cf _all using cc_1_10_pll

timer list
