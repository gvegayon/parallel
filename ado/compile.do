set matadebug off
set trace off

*clear all
program drop _all
macro drop _all
mata mata clear
set matastrict on

//use when debugging 
//  See also matadebug setting in setup_ado.do
//set matalnum on 

vers 11.0

/* Build documentation */
mata:
archmata = dir(".","files","*.mata")
//This includes for users some mata files not put in mlib: parallel_for, parallel_montecarlo
_sort(archmata,1)
dt_moxygen(archmata, "parallel_source.sthlp", 1)

end

if `c(stata_version)'>=12 di "WARNING: compiled mlib will only work on Stata version >=`c(stata_version)'"

/* Compiling */
run parallel_setclusters.mata
run parallel_run.mata 
do parallel_write_do.mata
run parallel_export_programs.mata
run parallel_export_globals.mata  
run parallel_randomid.mata     	
run parallel_finito.mata
run parallel_setstatapath.mata
run parallel_normalizepath.mata
run parallel_clean.mata
run parallel_write_diagnosis.mata
run parallel_break.mata
run parallel_sandbox.mata
run parallel_expand_expr.mata
//eststore is "hidden" (undocumented and not called by normal functioning) utility
run parallel_eststore.mata
run parallel_recursively_rm.mata

cap rm lparallel.mlib
mata: mata mlib create lparallel, replace
mata: mata mlib add lparallel parallel_*() _parallel_*()

/*
/* Creando checksum */
mata st_global("ayuda",invtokens(dir(".","files","*.hlp")'))
mata st_global("ados",invtokens(dir(".","files","*.ado")'))

foreach g in ayuda ados {
	foreach f of global `g' {
		checksum `f', save replace
	}
}
checksum lparallel.mlib, save replace
*/




