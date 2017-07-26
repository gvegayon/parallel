SHELL := /bin/bash
PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/:$(PATH)
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do test_length.do test_aux_out.do
TESTS_LOGS=test_bs.log test_append.log test_sim.log test_prefix.log test.log \
	test_append_loop.log test_length.do test_aux_out.log
#Not currently using: test_sim_within_sim.do
#Test the cluster by specifying hostnames via env variable PLL_TEST_NODES

#Provide an override for stata location
ifeq "$(STATABATCH)" ""
  STATABATCH:=stata -b
endif

.PHONY: compile home inc_dist_date clean tests checks check_version releasehelp release

compile: inc_dist_date
	$(STATABATCH) do compile.do
	@echo Other helpful targets include: tests, checks, clean, and releaseinfo
help:
	@echo Helpful targets include: compile, tests, checks, clean, releasehelp, release
releasehelp:
	@echo Make sure you run tests \(on Stata v11\)
	@echo Make sure you run the checks.
	@echo Make sure you bump the version and -make inc_dist_date-
	@echo Make sure you editted the Changelog
	@echo After pushing to github, go to https://github.com/gvegayon/parallel/releases and make a release

home:
	$(STATABATCH) do compile_and_install.do
	make clean
clean:
	less compile_and_install.log
	rm -f compile_and_install.log
	rm -f __pll*
	-rm -f -r /tmp/__pll*

release: checks tests releasehelp

include codechecks.mk

checks: code_checks check_version

check_version:
	@echo "Visually ensure numbers are the same"
	grep '"vers"' parallel.ado
	grep "pll_vers" parallel.ado
	grep "*! version" parallel.sthlp
	grep "*! version" parallel.ado
	@echo ""

inc_dist_date:
	sed -ie "s/\(d Distribution-Date: \).\+/\1$$(date +%Y%m%d)/g" ../parallel.pkg

tests: 
	@echo Running tests 
	@echo When looking at the combined log, search for "^r\(".
	echo $$PATH > temp.txt
	cd "../test files" && if [ ! -f platformname.txt ]; then $(STATABATCH) do export_platformname.do platformname.txt; fi;
	cd "../test files" && \
		PLAT=$$(<platformname.txt) && \
		export S_ADO="../ado/;../ado/$$PLAT;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE" && \
		export STATATMP=. && \
		for i in $(TESTS) ; do \
			$(STATABATCH) do $${i}; \
			echo test $${i} done; \
		done ; \
		cat $(TESTS_LOGS) > all_tests_results.txt; \
		less all_tests_results.txt;

