* Test cmd_list
clear all
parallel initialize 2

* Simple program to find the row with the maximum value of the passed in variable
cap program drop max_row
program max_row
    syntax varlist, out(string)
    summ `varlist'
    keep if `varlist'==`r(max)'
    keep in 1
    gen str16 max_var = "`varlist'" 
    save "`out'", replace
end

loc append_list ""
foreach v in price mpg {
    tempfile tf_`v'
    cmd_list add: max_row `v', out(`tf_`v'')
    loc append_list `"`append_list' "`tf_`v''""'
}

cmd_list view

* Run and compile results for parallel and sequential
tempfile par_out seq_out
sysuse auto
cmd_list run, parallel nocleanup programs(max_row)
drop _all
append using `append_list'
sort max_var
save "`par_out'"

sysuse auto
cmd_list run, nocleanup
drop _all
append using `append_list'
sort max_var
save "`seq_out'"

* Compare results
use "`par_out'"
cf _all using "`seq_out'"


cmd_list view
cmd_list clear
cmd_list view
