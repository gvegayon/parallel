////////////////////////////////////////////////////////////////////////////////
// EJEMPLOS PARA PREENTACION INTERNA DE LA SUPER DE PENSIONES
////////////////////////////////////////////////////////////////////////////////
clear all
set more off

cd "/u1/users/estudios/investigacion/george/comandos_paquetes_librerias/stata/parallel/"

texdoc init presentaciones/20130618_seminario_instituto_econ_uc/ejemplo_setup.tex, replace
// Base de datos a utilizar para ejemplos
texdoc stlog
sysuse bplong.dta
sort patient
parallel setclusters 4
texdoc stlog close
texdoc close

////////////////////////////////////////////////////////////////////////////////
// Egenerando
texdoc init presentaciones/20130618_seminario_instituto_econ_uc/ejemplo_egenby.tex, replace
texdoc stlog
bysort patient: egen max_bp = max(bp)
parallel, by(patient) nog: by patient: egen max_bp_pll = max(bp)
summ max_bp*
texdoc stlog close
texdoc close
// Comparando 

////////////////////////////////////////////////////////////////////////////////
// Reshape
texdoc init presentaciones/20130618_seminario_instituto_econ_uc/ejemplo_reshapeby.tex, replace
texdoc stlog
qui reshape wide bp max_bp*, i(patient) j(when)
summ 
qui reshape long
qui parallel, by(patient) f nog: reshape wide bp max_bp*, i(patient) j(when)
return list
summ
texdoc stlog close
texdoc close
