DIR=~/parallel/ado
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do
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

tests:
	echo Running tests &
	for i in $(TESTS) ; do \
		cd ../tests/ && stata -b do $${i}&&echo test $${i} done; \
	done ; \
	stata -b do merge_all_tests.do;\
	less all_tests_results.txt
