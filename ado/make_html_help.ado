//Use log2html. Couldn't get parse-smcl to work with code that had tabs (loops).
program make_html_help
	syntax anything
	copy `anything'.sthlp `anything'.smcl, replace
	//linesize needs to be sufficiently long or lines with quotes get cut-off and mis-parsed
	log2html `anything', replace linesize(145)
	erase `anything'.smcl
end
