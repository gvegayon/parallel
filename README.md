parallel
========

PARALLEL: Stata module for parallel computing

Parallel lets you **run Stata faster**, sometimes faster than MP itself. By organizing your job in several Stata instances, parallel allows you to work with out-of-the-box parallel computing. Using the the 'parallel' prefix, you can get **faster simulations, bootstrapping, reshaping big data**, etc. without having to know a thing about parallel computing. With **no need of having Stata/MP** installed on your computer, parallel has showed to dramatically speedup computations up to two, four, or more times depending on how many processors your computer has.

Stata conference presentation: <http://ideas.repec.org/p/boc/norl13/4.html>

SSC at Boston College: <http://ideas.repec.org/c/boc/bocode/s457527.html>

Install
=======

For accessing SSC version of parallel
```Stata
. ssc install parallel, replace
. mata mata mlib index
```

For accessing the latest development version of parallel (from here) using Stata version >=13

```Stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/master/) replace
. mata mata mlib index
```

For Stata version <13, download as zip, unzip, and then replace the above -net install- with

```Stata
. net install parallel, from(full_local_path_to_files) replace
```

Once installed it is suggested to restart Stata. If you had a previous installation of -parallel- installed from a different source you should uninstall that first.

Author
======
George G. Vega [aut,cre]
gvegayon (at) caltech dot edu

Brian Quistorff [ctb]
