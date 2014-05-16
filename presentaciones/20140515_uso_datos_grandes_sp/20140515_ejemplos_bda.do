cd ~/parallel/ado
do compile

clear all
set more off
set trace off
timer clear

cap log close _all
log using logbda.txt, replace text

global bda ~/../shared_bd/bases/bda/bases_stata
cd $bda

parallel clean, all force
parallel setclusters 2, f

//////////////////////////////////////////////////////////////////////
// EJEMPLO PARALLEL BY
//////////////////////////////////////////////////////////////////////
use $bda/2013_06/pers

gen nacimiento = date(strofreal(fec_nac, "%12.0f"), "YMD")
parallel:gen nacimiento2 = date(strofreal(fec_nac, "%12.0f"), "YMD")
compare nacimiento nacimiento2

clear

//////////////////////////////////////////////////////////////////////
// EJEMPLO PARALLEL APPEND
//////////////////////////////////////////////////////////////////////
/* Ejemplo BDA 1 */
set trace on
parallel append 2013_01/mcci 2013_02/mcci 2013_03/mcci, ///
	do(collapse (mean) monto_pe, by(perdev) fast) ///
	if(inlist(cod_mov, 11001, 11010))


/* Ejemplo BDA 2*/
cap program drop miprograma
program def miprograma
	/* Capturando la variable de sexo */
	merge m:m correl using $bda/2013_06/pers, keep(3) nogen ///
		keepusing(correl sexo)

	collapse (mean) mprom = monto_pesos (sd) msd = monto_pesos, ///
		by(perdev_rem sexo) fast
end

/* Aplicando programa */
parallel append, do(miprograma) programs(miprograma) ///
	e("%g_%02.0f/mcci.dta, 2010/2013, 1 6 12") if(inlist(cod_mov, 11001, 11010))

summ
d


/* Aplicando lo mismo pero a un set restringido */
parallel append, do(miprograma) programs(miprograma) ///
	e("%g_%02.0f/mcci.dta, 2010/2013, 1 6") ///
	if(inlist(cod_mov, 11001, 11010))

summ
d


log close
