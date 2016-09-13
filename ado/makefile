SHELL := /bin/bash
PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/stata12/:$(PATH)
TESTS=test_bs.do test_append.do test_sim.do test_prefix.do test.do \
	test_append_loop.do test_length.do
TESTS_LOGS=test_bs.log test_append.log test_sim.log test_prefix.log test.log \
	test_append_loop.log test_length.do

#Provide an override for stata location
ifeq "$(STATABATCH)" ""
  STATABATCH:=stata -b
endif

.PHONY: home compile inc_dist_date clean tests checks check_smcl check_missing_tempname check_macro_exp_mata check_version

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
	
checks: check_smcl check_missing_tempname check_macro_exp_mata check_version
	
#Smcl has problems displaying lines over 244 characters
check_smcl:
	@echo "Will display lines if error"
	-grep '.\{245\}' *.sthlp
	@echo ""
	
#Ideally check for other named things like graph names.
check_missing_tempname :
	@echo Checking for ados with missing tempname and instead use scalars
	X=$$(grep "file open [^\`]" *.ado); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	X=$$(grep "^\s\+\(qui \)\?scalar [^\`]" *.ado | grep -v "scalar define \`"); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	X=$$(grep "^\s\+mat\(rix\)\? [^\`\$$]" *.ado | grep -v "\(row\|col\)\(n\(ames\?\)\?\|eq\)" | grep -v " li\(st\)\?" | grep -v " drop" | grep -v " input [\`\$$]"); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	
check_macro_exp_mata :
	@echo Checking for mata files that accidentally use macro exp
	@echo which happens at compile time and not runtime.
	@echo Will display lines if errors.
	@echo Some false-positives in parallel_eststore.mata
	-X=$$(grep "\`[^\"]\+\'" *.mata); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	-X=$$(grep '\$$[\{a-zA-Z_]' *.mata); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	
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
