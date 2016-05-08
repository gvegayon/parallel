SHELL := /bin/bash
PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/:$(PATH)
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do

#Provide an override for stata location
ifeq "$(STATABATCH)" ""
  STATABATCH:=stata-mp -b
endif

.PHONY: sp home compile inc_dist_date clean tests

sp :
	$(STATABATCH) do compile_and_install.do;cp -u -r ~/parallel ~/../investigacion/george/comandos_paquetes_librerias/stata
	make clean
home:
	$(STATABATCH) do compile_and_install.do
	make clean
inc_dist_date:
	sed -ie "s/\(d Distribution-Date: \).\+/\1$$(date +%Y%m%d)/g" ../parallel.pkg
compile: inc_dist_date
	$(STATABATCH) do compile.do
clean:
	less compile_and_install.log
	rm -f compile_and_install.log
	rm -f __pll*
	-rm -f -r /tmp/__pll*
	
#Smcl has problems displaying lines over 244 characters
check_smcl:
	@echo "Will display lines if error"
	-grep '.\{245\}' *.sthlp
	@echo ""
	
check_version:
	@echo "Visually ensure numbers are the same"
	grep '"vers"' parallel.ado
	grep "pll_vers" parallel.ado
	grep "*! version" parallel.sthlp
	grep "*! version" parallel.ado
	@echo ""

#in the Win part below, it's hard to easily get the PID of 'tail' in 'tail -f file| bash'.
# see http://stackoverflow.com/questions/1652680/. 
#  The "redirect to a subshell" doesn't seem to work any more on Cygwin
tests: 
	@echo Running tests 
	@echo When looking at the combined log, search for "with error" and "^r\(".
	echo PATH > temp.txt
	
	export S_ADO="../ado/;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE" && \
		cd ../tests && \
		if [ "$$OS" = "Windows_NT" ]; then rm -f pll_gateway.sh; touch pll_gateway.sh; ( tail -f pll_gateway.sh & echo $$! >&3 ) 3>pid | bash & fi; \
		for i in $(TESTS) ; do \
			$(STATABATCH) do $${i}; \
			echo test $${i} done; \
		done ; \
		if [ "$$OS" = "Windows_NT" ]; then kill $$(<pid); rm -f pll_gateway.sh pid; fi; \
		cat *.log > all_tests_results.txt; \
		less all_tests_results.txt;
