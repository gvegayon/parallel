set matadebug off
set trace off
local oldcd = c(pwd)

*clear all
program drop _all
macro drop _all
mata: mata clear
set matastrict on

vers 10.0

/* Build documentation */
if (c(os)=="Windows") {
	cap run i:/george/comandos_paquetes_librerias/stata/dev_tools/build_source_hlp.mata
}
else {
	cap run ../../dev_tools/build_source_hlp.mata
	cap run ~/../investigacion/george/comandos_paquetes_librerias/stata/dev_tools/build_source_hlp.mata
}

mata:
archmata = dir(".","files","*.mata")
_sort(archmata,1)
build_source_hlp_pll(archmata, "parallel_source.hlp", 1)
mata clear
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

mata: mata mlib create lparallel, replace
mata: mata mlib add lparallel *()

/* Creando checksum */
mata st_global("ayuda",invtokens(dir(".","files","*.hlp")'))
mata st_global("ados",invtokens(dir(".","files","*.ado")'))

foreach g in ayuda ados {
	foreach f of global `g' {
		checksum `f', save replace
	}
}
checksum lparallel.mlib, save replace



