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

//make the HTML version of help
//Use log2html. Couldn't get parse-smcl to work with code that had tabs (loops).
copy parallel.sthlp parallel.smcl, replace
//linesize needs to be sufficiently long or lines with quotes get cut-off and mis-parsed
log2html parallel, replace linesize(145)
erase parallel.smcl

copy seeding.sthlp seeding.smcl, replace
log2html seeding, replace linesize(145)
erase seeding.smcl

if `c(stata_version)'>=12 di "WARNING: compiled mlib will only work on Stata version >=`c(stata_version)'"

/* Compiling */
//"run" will be silent whereas "do" will show code and mata interpreter warnings
//Nice check is to use "do" and check for "note:" entries that say things like "variable unused".
local do_or_run "run"
`do_or_run' parallel_initialize.mata
`do_or_run' parallel_run.mata 
`do_or_run' parallel_write_do.mata
`do_or_run' parallel_export_programs.mata
`do_or_run' parallel_export_globals.mata  
`do_or_run' parallel_randomid.mata     	
`do_or_run' parallel_finito.mata
`do_or_run' parallel_setstatapath.mata
`do_or_run' parallel_normalizepath.mata
`do_or_run' parallel_clean.mata
`do_or_run' parallel_write_diagnosis.mata
`do_or_run' parallel_break.mata
`do_or_run' parallel_sandbox.mata
`do_or_run' parallel_expand_expr.mata
//eststore is "hidden" (undocumented and not called by normal functioning) utility
`do_or_run' parallel_eststore.mata
`do_or_run' parallel_recursively_rm.mata

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




