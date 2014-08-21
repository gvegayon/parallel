*! Testing prefix syntax
*! version 1.14.6.24 24jun2014
set trace off
clear all
set more off

vers 11.0

global clusters 1 2 3 4 5 6 7 8

/* Listing prefix operations tested*/
local test1 gen x = 1
local test2 by rep78: gen x = _N
local test3 gen x = price if price < 5000
local test4 by rep78: egen x = sum(price)
local test5 by rep78: egen x = sum(price) if price < 5000

local i=0
while ("`test`++i''" != "") {
	local db`i' sysuse auto, clear
}

foreach c of global clusters {
	parallel setclusters `c'
	local i=0
	while ("`test`++i''" != "") {
		quietly {
			timer clear

			/* Loading DB */
			`db`i''
	
			/* Checking out sorting */
			if (regexm(`"`test`i''"',"^by ([a-zA-Z0-9_ ]+)[:]")) {
				local by = regexs(1)
				sort `by'
				local by = "by(`by') force"
			}
	
			/* Serial fashion */
			timer on 1
			`test`i''
			timer off 1
			ren x xserial

			/* Parallel fashion */
			cap parallel, `by' nog: `test`i''
			local t2 = r(pll_t_fini) + r(pll_t_calc) + r(pll_t_setu)

			if (_rc) continue	

			gen equal = x == xserial

			summ equal
			if (r(mean)==1) local results EQUAL
			else local results UNEQUAL

			timer list
			if (r(t1) != .) local t1 = r(t1)
			else local t1 = 0
		}
	
		di as result %-8s "`results'" " t1/t2: " %05.2fc `t1'/`t2'*100 ///
			" CLUSTERS: " %2.0fc $PLL_CLUSTERS  `" CMD: `test`i''"' as text
	}
}

