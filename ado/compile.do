set matadebug off
set trace off
local oldcd = c(pwd)

*clear all
program drop _all
macro drop _all
mata mata clear
set matastrict on

vers 10.0

/* Build documentation */
mata:
archmata = dir(".","files","*.mata")
_sort(archmata,1)
dt_moxygen(archmata, "parallel_source.hlp", 1)

end

/* Compiling */
run parallel_setclusters.mata
run parallel_run.mata 
run parallel_write_do.mata
run parallel_export_programs.mata
run parallel_export_globals.mata  
run parallel_randomid.mata     	
run parallel_finito.mata
run parallel_setstatadir.mata
run parallel_normalizepath.mata
run parallel_clean.mata
run parallel_divide_index.mata
run parallel_write_diagnosis.mata
run parallel_break.mata
run parallel_sandbox.mata
run parallel_expand_expr.mata

rm lparallel.mlib
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

cd ..

mata: dt_install_on_the_fly("parallel")



