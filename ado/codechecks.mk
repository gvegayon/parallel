.PHONY: code_checks check_smcl check_missing_tempname check_macro_exp_mata check_shortcircuit

code_checks: check_smcl check_missing_tempname check_macro_exp_mata check_shortcircuit
	
#Smcl has problems displaying lines over 244 characters
check_smcl:
	@echo "Will display lines if error"
	-grep '.\{245\}' *.sthlp
	@echo ""

#mata doesn't do short-circuit logical evaluation.
check_shortcircuit:
	@echo "Will display lines if error"
	-grep "[&|].\+[^!=<>]=[^=].*)" *.mata | grep "\(if\|while\)"
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
