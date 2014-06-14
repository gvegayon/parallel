DIR=~/parallel/ado
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/
sp :
	stata-mp -b do compile.do;cp -u -r ~/parallel ~/../investigacion/george/comandos_paquetes_librerias/stata
	make clean
home:
	stata -b do compile.do
	make clean
clean:
	less compile.log
	rm -f compile.log
	rm -f __pll*
	rm -f -r /tmp/__pll*
