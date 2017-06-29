////////////////////////////////////////////////////////////////////////////////
// EJEMPLOS PARA PREENTACION INTERNA DE LA SUPER DE PENSIONES
////////////////////////////////////////////////////////////////////////////////
clear all
set more off

cd "/u1/users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/"

// Carga ultima version de parallel
run ado/parallel.ado

texdoc init presentaciones/20121220_seminario_interno_sp/ejemplo_setup.tex, replace
// Base de datos a utilizar para ejemplos
texdoc stlog
sysuse bplong.dta
sort patient
parallel setclusters 4
texdoc stlog close
texdoc close

////////////////////////////////////////////////////////////////////////////////
// Egenerando
texdoc init presentaciones/20121220_seminario_interno_sp/ejemplo_egenby.tex, replace
texdoc stlog
bysort patient: egen max_bp = max(bp)
parallel, by(patient) nog: by patient: egen max_bp_pll = max(bp)
summ max_bp*
texdoc stlog close
texdoc close
// Comparando 

////////////////////////////////////////////////////////////////////////////////
// Reshape
texdoc init presentaciones/20121220_seminario_interno_sp/ejemplo_reshapeby.tex, replace
texdoc stlog
qui reshape wide bp max_bp*, i(patient) j(when)
summ 
qui reshape long
qui parallel, by(patient) f nog: reshape wide bp max_bp*, i(patient) j(when)
return list
summ
texdoc stlog close
texdoc close
