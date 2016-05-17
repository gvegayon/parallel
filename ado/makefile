SHELL := /bin/bash
PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/:$(PATH)
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do
TESTS_LOGS=test_bs.log test_append.log test_sim.log test_prefix.log test.log \
	test_append_loop.log

#Provide an override for stata location
ifeq "$(STATABATCH)" ""
  STATABATCH:=stata -b
endif

.PHONY: home compile inc_dist_date clean tests

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
	@echo When looking at the combined log, search for "^r\(".
	echo $$PATH > temp.txt
	cd ../tests && if [ ! -f platformname.txt ]; then $(STATABATCH) do export_platformname.do platformname.txt; fi;
	cd ../tests && \
		PLAT=$$(<platformname.txt) && \
		export S_ADO="../ado/;../ado/$$PLAT;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE" && \
		for i in $(TESTS) ; do \
			$(STATABATCH) do $${i}; \
			echo test $${i} done; \
		done ; \
		cat $(TESTS_LOGS) > all_tests_results.txt; \
		less all_tests_results.txt;
