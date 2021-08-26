*! _seeded_cmd_wrapper
*! auth Brian Quistorff
program _seeded_cmd_wrapper
	* Determines which rep we are in, sets the seed, and does one execution of cmd,
	* then increments counter.
	gettoken sub_cmd 0 : 0
	if "`sub_cmd'"=="permute" gettoken permvar 0 : 0
	gettoken seeds cmd : 0
	*local seeds seeds
	local s = `=`seeds'[$REP_lc_i,1]'
	set seed `s'
	//nothing if "`sub_cmd'"=="simulate" //simulate doesn't preserve
	if "`sub_cmd'"=="bootstrap" {
		preserve
		bsample
	}
	if "`sub_cmd'"=="permute" {
		preserve
		permute_once `permvar'
	}
	`cmd'
	global REP_lc_i = $REP_lc_i + 1
	global REP_gl_i = $REP_gl_i + 1
end

program permute_once
	* No builtin cmd for just permuting a variable
	*https://journals.sagepub.com/doi/pdf/10.1177/1536867X1101000410
	args permvar

	tempvar id u upermvar
	generate `id'=_n
	generate double `u'=runiform()
	sort `u'
	local type: type `permvar'
	generate `type' `upermvar'=`permvar'[`id']
	sort `id'
	replace `permvar' = `upermvar'
end
