SHELL := /bin/bash
PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/:$(PATH)
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do

#Provide an override for stata location
ifeq "$(STATABATCH)" ""
  STATABATCH:=stata-mp -b
endif

sp :
	$(STATABATCH) do compile_and_install.do;cp -u -r ~/parallel ~/../investigacion/george/comandos_paquetes_librerias/stata
	make clean
home:
	$(STATABATCH) do compile_and_install.do
	make clean
clean:
	less compile_and_install.log
	rm -f compile_and_install.log
	rm -f __pll*
	-rm -f -r /tmp/__pll*

tests: 
	@echo Running tests 
	cd ../tests && \
		if [ "$$OS" = "Windows_NT" ]; then rm -f pll_gateway.sh; touch pll_gateway.sh; tail -f pll_gateway.sh > >( bash ) & tail_pid=$$!; fi; \
		for i in $(TESTS) ; do \
			$(STATABATCH) do $${i}; \
			echo test $${i} done; \
		done ; \
		if [ "$$OS" = "Windows_NT" ]; then kill $$tail_pid; rm -f pll_gateway.sh; fi; \
		cat *.log > all_tests_results.txt; \
		less all_tests_results.txt;
