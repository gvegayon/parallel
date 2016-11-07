/*
Benchmark program

This dofile describes takes the output from 01_parellel_benchmark.do and
creates a plot and a table.

This is work-in-progress.
*/ 

clear all

set more off
set trace off

// Parameters
global DATE         20161102
global nreps        1000
global TEST         BOOTTEST
global PROCESSOR    "Intel Core i7-4790 CPU @ 3.60GHz × 8"

m: st_global("filename", sprintf("%f_parallel-bechmark_nreps=%04.0f.dta",$DATE, $nreps))

use "$filename", clear

// Getting the parameters
local statav : display %3.1f stata_version[1]
global whichstata = "Stata `=flavor[1]' `statav' on a `=os[1]' machine with an $PROCESSOR processor"

// Filtering data and stacking times and nclusters
keep if test == "$TEST"
mata:
TIMES = st_data(.,"tot_pll")\st_data(.,"tot_serial")
PSIZE = st_data(.,"problem_size")\st_data(.,"problem_size")
NCLUS = st_data(.,"nclusters")\J(st_nobs(),1,1)
st_local("n", strofreal(st_nobs()*2))
end

// Storing the data back into stata
drop _all
set obs `n'
gen double time    = .
gen double psize   = .
gen double nclusts = .

mata: st_store(.,.,(TIMES, PSIZE, NCLUS))

// Reshaping to be used as time series
collapse (mean) avg_time=time, by(nclusts psize)

reshape wide avg_time, i(psize) j(nclusts)
// Adding labels
lab var avg_time1 "Serial"
lab var avg_time2 "2 Clusters"
lab var avg_time4 "4 Clusters"
lab var psize "Problem size"

graph twoway (connected avg* psize), ///
	ytitle(Total Time (in secs.)) scheme(sj) ///
	legend(rows(1) lstyle(transparend) subtitle(Method)) ///
	note( ///
	"Each point represents `=$nreps' runs of the problem." ///
	"$whichstata" ///
	)

graph export "tables_and_figures/parallel_benchmarks_test=`=lower("$TEST")'.eps", replace

// Function to print data
mata:
psize    = st_data(.,"psize")
avgtimes = st_data(.,2..st_nvar())
fn       = "tables_and_figures/parallel_benchmarks_test=`=lower("$TEST")'.tex"
if (fileexists(fn)) unlink(fn)
fh       = fopen(fn, "w")
	
// fput(fh, "\begin{tabular}{*{2}{m{.2\textwidth}}*{2}{m{.25\textwidth}}}")
fput(fh, "\centering\begin{tabular}{l*{3}{c}}")
fput(fh, "\toprule")
fput(fh, "Problem size & Serial & 2 Clusters & 4 Clusters\\\midrule")
for(i=1;i<=length(psize);i++) {

	// Times
	fwrite(fh, sprintf("%3.0f", psize[i]))
	for(j=1;j<=cols(avgtimes);j++) {
		// ans = ans + " &  "  + sprintf("%5.2f", avgtimes[i,j])
		fwrite(fh, " &  "  + sprintf("%5.2fs", avgtimes[i,j]))
	}
	
	fput(fh, " \\    ")
	
	// Relative times
	tmp = 1:/(J(1,cols(avgtimes),min(avgtimes[i,.])) :/avgtimes[i,.])
	for(j=1;j<=length(tmp);j++) {
		fwrite(fh, " &  x"  + sprintf("%4.2f", tmp[j]))
	}
	
	if (i != length(psize)) fput(fh, " \\ \\")
	else fput(fh, " \\")
}

fput(fh, "\bottomrule")
fput(fh, "\end{tabular}")
fclose(fh)
end
