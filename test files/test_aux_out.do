do setup_ado.do
program drop _all
macro drop _all
sysuse auto, clear
global nCl = 3
parallel setclusters $nCl, force
set seed 1337

cap program drop my_prog
program my_prog
	syntax, output(string)
	
	save "`output'", replace
end

sysuse auto
sort make
datasignature

tempfile outputfile_seq outputfile_par

my_prog, output(`outputfile_seq')
use "`outputfile_seq'", replace
datasignature
local sig_seq "`r(datasignature)'"

sysuse auto
parallel, outputopts(output) programs(my_prog): my_prog, output(`outputfile_par')
use "`outputfile_par'", replace
datasignature
local sig_par "`r(datasignature)'"

_assert "`sig_seq'"=="`sig_par'"
