/*

clear all
set more off
//set trace off

set mem 300m

if "$S_OS" == "Windows" cd "C:\Users\George\Documents\Programacion\stata_super\parallel\man"
else cd /users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/man

run ../ado/parallel.ado
run ../../tabular.do

// Test en un set de datos normal
if "$S_OS" == "Windows" parallel setclusters 2
else parallel setclusters 2

set obs 10000000
set seed 123
gen normal1 = rnormal()
gen uniform1 = runiform()
gen id = _n if mod(_n,2) == 0
replace id = id[_n + 1] if id == .
sort id
compress


// Pruebas 1
foreach size in 1000 10000 100000 1000000 10000000 {
	timer clear
	preserve
	keep in 1/`size'
	forval i = 1/3 {
		
		cap drop normal1_np
		cap drop normal1_p
		gen normal1_np = normal1
		gen normal1_p = normal1
		
		// No paralelo
		sort id
		timer on 1
		local maxiter = _N
		forval i = 1/`maxiter' {
			qui replace normal1_np = normal1 < rnormal() in `i'
		}
		timer off 1
		
		timer on 2
		parallel do loop.do, keep
		timer off 2
		
	}
	
	timer list

	// CPU
	local t1 = `r(t1)'/`r(nt1)'
	
	// Parallel
	local t2 = `r(t88)'/`r(nt88)'
	
	// Setup
	local t3 = `r(t99)'/`r(nt99)'
	
	// Total
	local total = `t2' + `t3'
	
	local better = `t1'/`t2'
	local bettertot = `t1'/`total'
	
	if `size' == 1000 {
		mat def tiempos = `t1'\ `t3'\ `t2'\ `total'\ `better'\ `bettertot'
	}
	else {
		mat def tiempos = tiempos, (`t1'\ `t3'\ `t2'\ `total'\ `better'\ `bettertot')
	}
	restore
}

if "$S_OS" == "Windows" {
	tabular tiempos using tiempos_replace_windows$PARALLEL_CLUSTERS.tex, replace ///
		rowname("CPU" "Setup" "Parallel" "Total" "Ratio (compute)" "Ratio (total)") ///
		colname(1.000 10.000 100.000 1.000.000 10.000.000) ///
		caption(Performance of simple model) pos(!h)
}
else {
	tabular tiempos using tiempos_replace_linux$PARALLEL_CLUSTERS.tex, replace ///
		rowname("CPU" "Setup" "Parallel" "Total" "Ratio (compute)" "Ratio (total)") ///
		colname(1.000 10.000 100.000 1.000.000 10.000.000) ///
		caption(Performance of simple model) pos(!h)
}

*/
	
// Pruebas 2
////////////////////////////////////////////////////////////////////////////////
// SCRIPT DE PRUEBA DEL PROGRAMA pensionsim para RENTAS TOPE
// Este script genera una base de datos aleatoria de 998 cotizantes con las var
// iables listadas abajo y, utilizando el comando "pensionsim"
////////////////////////////////////////////////////////////////////////////////

clear all
mata: mata clear
set more off

if ("`c(os)'"=="Windows") global pensionsim "i:/george/comandos_paquetes_librerias/stata/pensionsim"
if ("`c(os)'"=="Unix") global pensionsim "/users/estudios/investigacion/george/comandos_paquetes_librerias/stata/pensionsim"


if "$S_OS" == "Windows" cd "C:\Users\George\Documents\Programacion\stata_super\parallel\man"
else cd /users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/man

// Carga programa
run $pensionsim/ado/pensionsim.ado
run ../ado/parallel.ado
run ../../tabular.do


// Primera observacion conocida
set obs 4
gen byte mujer = 0
gen byte edad = 25
gen byte edad_jubila = 35
gen float ahorro_obligatorio = 100
gen float bono_reconocimiento = 10
gen float ahorro_voluntario = 5
gen float apv1 = 2
gen float apv2 = 2
gen float apv3 = 2
gen float cuenta_dos = 10
gen float rem_imponible = 119
gen float rem_imponible1 = 20
gen float rem_imponible2 = 30
gen float rem_imponible3 = 25
gen float deposito_convenido = 10
gen byte regularidad_cotiza = 12
gen byte regularidad_cotiza1 = 8
gen byte regularidad_cotiza2 = 7
gen byte regularidad_cotiza3 = 6
gen int estrategia_inv = 234

// Segunda (mujer)
replace mujer = 1 if _n == 2

// Tercero y cuarto otra combinacion
replace mujer = 0 if _n > 2
replace edad = 25 if _n > 2
replace edad_jubila = 65 if _n > 2
replace ahorro_obligatorio = 100 if _n > 2
replace bono_reconocimiento = 0 if _n > 2
replace ahorro_voluntario = 5 if _n > 2
replace apv1 = 2 if _n > 2
replace apv2 = 2 if _n > 2
replace apv3 = 2 if _n > 2
replace cuenta_dos = 10 if _n > 2
replace rem_imponible = 95 if _n > 2
replace rem_imponible1 = 20 if _n > 2
replace rem_imponible2 = 30 if _n > 2
replace rem_imponible3 = 25 if _n > 2
replace deposito_convenido = 10 if _n > 2
replace regularidad_cotiza = 12 if _n > 2
replace regularidad_cotiza1 = 8 if _n > 2
replace regularidad_cotiza2 = 7 if _n > 2
replace regularidad_cotiza3 = 6 if _n > 2
replace estrategia_inv = 234 if _n > 2

// Cuarto (mujer)
replace mujer = 1 if _n == _N
local n = _N

// 999 Observaciones aleatorias
set obs 5000	
set seed 10
replace mujer = 0+int((1-0+1)*runiform()) if _n > `n'
replace edad = 18 + (1+int((60-1+1)*runiform())) if _n > `n'
replace edad_jubila = edad - 5*mujer + (10+int((5-1+1)*runiform())) if _n > `n'
replace ahorro_obligatorio = max(0,200 + rnormal(100,100)) if _n > `n'
replace ahorro_voluntario = max(0,0 + rnormal(10,15)) if _n > `n'
replace apv1 = max(0,rnormal(3,3)) if _n > `n'
replace apv2 = max(0,rnormal(3,3)) if _n > `n'
replace apv3 = max(0,rnormal(3,3)) if _n > `n'
replace cuenta_dos = max(0,0 + rnormal(10,15)) if _n > `n'
replace bono_reconocimiento = max(0,0 + rnormal(10,15)) if _n > `n'
replace rem_imponible = 5 + (200-0+1)*runiform() if _n > `n'
replace rem_imponible1 = max(0,0 + rnormal(10,20)) if _n > `n'
replace rem_imponible2 = max(0,0 + rnormal(10,20)) if _n > `n'
replace rem_imponible3 = max(0,0 + rnormal(10,20)) if _n > `n'
replace deposito_convenido = max(0,0 + rnormal(10,15)) if _n > `n'
replace regularidad_cotiza = min(12,8 + ceil(rnormal(2))) if _n > `n'
replace regularidad_cotiza1 = min(12,8 + ceil(rnormal(2))) if _n > `n'
replace regularidad_cotiza2 = min(12,7 + ceil(rnormal(3))) if _n > `n'
replace regularidad_cotiza3 = min(12,6 + ceil(rnormal(4))) if _n > `n'
replace estrategia_inv = (1+int((5-1+1)*runiform()))*100 + (1+int((5-1+1)*runiform()))*10 ///
	+ 1+int((5-1+1)*runiform()) if _n > `n'

gen id = _n
	
compress

forval j = 2/8 {
	parallel setclusters `j'

	foreach size in 10 100 1000 5000 {
		timer clear
		preserve
		
		keep in 1/`size'
		
		forval i = 1/3 {
			timer on 1
			pensionsim edad mujer ahorro_obligatorio, out(saldo_final_topeproy) y(rem_imponible) yactual replace rtimp(0.0175) nsim(10001) ///
				apv(ahorro_voluntario) bono(bono_reconocimiento) estrategia(estrategia_inv) apv_m(apv1 apv2 apv3) ///
				edadn(edad_jubila) rho(regularidad_cotiza) rhoactual cdos(cuenta_dos) dc(deposito_convenido)
			timer off 1
				
			parallel: pensionsim edad mujer ahorro_obligatorio, out(saldo_final_topeproy) y(rem_imponible) yactual replace rtimp(0.0175) nsim(10001) ///
				apv(ahorro_voluntario) bono(bono_reconocimiento) estrategia(estrategia_inv) apv_m(apv1 apv2 apv3) ///
				edadn(edad_jubila) rho(regularidad_cotiza) rhoactual cdos(cuenta_dos) dc(deposito_convenido)
		}
			
		timer list

		// CPU
		local t1 = `r(t1)'/`r(nt1)'
		
		// Parallel
		local t2 = `r(t88)'/`r(nt88)'
		
		// Setup
		local t3 = `r(t99)'/`r(nt99)'
		
		// Total
		local total = `t2' + `t3'
		
		local better = `t1'/`t2'
		local bettertot = `t1'/`total'
		
		if `size' == 10 {
			mat def tiempospens = `t1'\ `t3'\ `t2'\ `total'\ `better'\ `bettertot'
		}
		else {
			mat def tiempospens = tiempospens, (`t1'\ `t3'\ `t2'\ `total'\ `better'\ `bettertot')
		}
		restore		
	}

	if "$S_OS" == "Windows" {
		tabular tiempospens using tiempos_pensionsim_windows$PARALLEL_CLUSTERS.tex, replace ///
			rowname("CPU" "Setup" "Parallel" "Total" "Ratio (compute)" "Ratio (total)") ///
			colname(10 100 1000 5000) ///
			caption(Performance of simple model) pos(!h)
		!git add -f tiempos_pensionsim_windows$PARALLEL_CLUSTERS.tex
	}
	else {
		tabular tiempospens using tiempos_pensionsim_linux$PARALLEL_CLUSTERS.tex, replace ///
			rowname("CPU" "Setup" "Parallel" "Total" "Ratio (compute)" "Ratio (total)") ///
			colname(10 100 1000 5000) ///
			caption(Performance of simple model) pos(!h)
		!git add -f tiempos_pensionsim_linux$PARALLEL_CLUSTERS.tex
	}
}

!git commit -a -m "Finishing pensionsim test for parallel paper"
!git push
