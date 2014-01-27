/* CREA ARCHIVO DE AYUDA PARA FUNCIONES MATA */

clear all
mata mata clear

cd I:\george\comandos_paquetes_librerias\stata\parallel\ado

run ../../dev_tools/build_source_hlp.mata

mata:

archmata = dir(".","files","*.mata")
_sort(archmata,1)
build_source_hlp(archmata, "parallel_source.sthlp", 1)
end
