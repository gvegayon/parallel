set matadebug off
set trace off
local oldcd = c(pwd)

if ("$S_OS" == "Windows") {
	net from I:\george\comandos_paquetes_librerias\stata
	cap cd I:\george\comandos_paquetes_librerias\stata\parallel\ado
}
else {
	cap net from ~/../investigacion/george/comandos_paquetes_librerias/stata
	cap cd ~/../investigacion/george/comandos_paquetes_librerias/stata/parallel/ado
	cap net from ~/Documents/programacion/stata_super
	cap cd ~/Documents/programacion/stata_super/parallel/ado
}
*clear all
program drop _all
macro drop _all
mata: mata clear
set matastrict on

vers 10.0

/* Build documentation */
run ../../dev_tools/build_source_hlp.mata

mata:
archmata = dir(".","files","*.mata")
_sort(archmata,1)
build_source_hlp(archmata, "parallel_source.hlp", 1)
end

/* Compiling */
run parallel_setclusters.mata
run parallel_run.mata 
run parallel_write_do.mata
run program_export.mata
run globals_export.mata  
run parallel_randomid.mata     	
run parallel_finito.mata
run parallel_setstatadir.mata
run normalizepath.mata
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


/* Empacando */
!zip parallel_0.13checksum.zip $ayuda $ados lparallel.mlib *.sum
!zip parallel_0.13.zip $ayuda $ados lparallel.mlib

cap net install parallel, force replace

mata: mata mlib index

parallel clean, all

sysuse auto, clear

parallel setclusters 2

/* Simple tests */
parallel, by(foreign) f keepl nog pro(2): egen maxp = max(price)
parallel, by(foreign) f keepl nog: egen maxp2 = max(price)
parallel, by(foreign) f keepl nog: gen n = _N

!less __pll`r(pll_id)'_do1.do

parallel clean, all

/* Testing cluster assigment */
parallel setclusters 5
sort rep78
parallel, by(rep78) f keepl nog: gen n2 = _N
parallel, by(rep78) f keepl nog: gen n3 = _N

/* Testing collapse */
tempfile original cllps1
save `original'

collapse (mean) price foreign, by(rep78)
save `cllps1'

use `original'
parallel, by(rep78) nog f: collapse (mean) price foreign, by(rep78)

cf _all using `cllps1'

if ("$S_OS" != "Windows") {
	parallel, nog nop keepl: mata: for(i=1;i<=1e6;i++) parallel_break()
}


