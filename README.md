parallel
========

PARALLEL: Stata module for parallel computing

Inspired in the R library “snow” and to be used in multicore CPUs, parallel implements parallel computing methods through  OS’s shell scripting (using Stata in batch mode) to accelerate computations. By starting a determined number of new Stata instances (child processes), this module allows the user to implement parallel computing methods without the need of having StataMP installed. Common tasks include vectorized operations, reshaping big data, running simulations (monte carlo experiments) or bootstrapping estimations. Depending on the number of cores of the CPU, parallel can reach linear speed ups significantly reducing computing wall-clock time. Finally parallel is, to the author’s knowledge, the first user contributed Stata module to implement parallel computing.

Stata conference presentation: [http://ideas.repec.org/p/boc/norl13/4.html]

SSC at Boston College: [http://ideas.repec.org/c/boc/bocode/s457527.html]

Install
=======

For accessing SSC version of parallel
```
. ssc install parallel, replace
. mata mata mlib index
```

For accessing the lastest version of parallel (dev)

```
. net install parallel, from(http://software.ggvega.com/stata) replace
. mata mata mlib index
```

Once installed it is suggested to restart Stata.

Author
======
George G. Vega
gvegayon (at) caltech dot edu
