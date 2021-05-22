<p align="center"><img src="logo/horizontal.png" alt="parallel" height="85px"></p>

PARALLEL: Stata module for parallel computing
=============================================

Parallel lets you **run Stata faster**, sometimes faster than MP itself. By organizing your job in several Stata instances, parallel allows you to work with out-of-the-box parallel computing. Using the the `parallel` prefix, you can get **faster simulations, bootstrapping, reshaping big data**, etc. without having to know a thing about parallel computing. With **no need of having Stata/MP** installed on your computer, parallel has showed to dramatically speedup computations up to two, four, or more times depending on how many processors your computer has.

See the HTML version of the program [help file](https://rawgit.com/gvegayon/parallel/master/ado/parallel.html) for more info. Other resources include the Stata 2017 conference [presentation](https://github.com/gvegayon/parallel/blob/master/talks/20170727_stata_conference/20170727_stata_conference_handout.pdf) and the SSC [page](http://ideas.repec.org/c/boc/bocode/s457527.html) at Boston College (though the SSC version is a bit out-of-date, see below).

1.  [Installation](#installation)
2.  [Minimal examples](#minimal-examples)
3.  [Authors](#authors)

Citation {#citation}
=======

When using `parallel`, please include the following:

Vega Yon GG, Quistorff B. parallel: A command for parallel computing. The Stata Journal. 2019;19(3):667-684. doi:10.1177/1536867X19874242

Or use the following bibtex entry:

```bib
@article{
  VegaYon2019,
  author = {George G. {Vega Yon} and Brian Quistorff},
  title ={parallel: A command for parallel computing},
  journal = {The Stata Journal},
  volume = {19},
  number = {3},
  pages = {667-684},
  year = {2019},
  doi = {10.1177/1536867X19874242},
  URL = {https://doi.org/10.1177/1536867X19874242},
  eprint = {https://doi.org/10.1177/1536867X19874242}
}
```

Installation
============

If you have a previous installation of `parallel` installed from a different source (SSC, specific folder, specific URL) you should uninstall that first (`ado uninstall parallel`). Once installed it is suggested to restart Stata.

GitHub
-----------------------------------

Stata version &gt;=13 can install the latest stable version using a GitHub URL,

``` stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
. mata mata mlib index
```

For Stata version &lt;13, [download as zip](https://github.com/gvegayon/parallel/archive/stable.zip), unzip, and then replace the above URL with the full local path to the files.

Latest version (master branch): Use the URL `https://raw.github.com/gvegayon/parallel/master/`. To get a zip click the "Clone or download" button and choose zip.


Older releases: Go to the [Releases Page](https://github.com/gvegayon/parallel/releases). You can use the release tag to in the URL (e.g., `https://raw.github.com/gvegayon/parallel/v1.15.8.19/`). See also the associated zip download option.

SSC
---

An older version is available from the SSC. It does not have all the bug fixes so it is not recommended to install it. If it is required, however, use

``` stata
. ssc install parallel, replace
. mata mata mlib index
```

Minimal examples
================

The following minimal examples have been written to introduce how to use the module. Please notice that the only examples actually designed to show potential speed gains are [parfor](#parfor) and [bootstrap](#bootstraping).

The examples have been executed on a Dell Vostro 3300 notebook running Ubuntu 14.04 with an Intel Core i5 CPU M 560 (2 physical cores) with 8Gb of RAM, using Stata/IC 12.1 for Unix (Linux 64-bit x86-64).

For more examples and details please refer to the module's help file or the wiki [Gallery page](https://github.com/gvegayon/parallel/wiki/Gallery).

Simple parallelization of egen
------------------------------

When conducted over groups, parallelizing `egen` can be useful. In the following example we show how to use `parallel` with `by: egen`.


    . parallel initialize 2, f
    N Clusters: 2
    Stata dir:  /usr/local/stata13/stata

    . sysuse auto
    (1978 Automobile Data)

    . parallel, by(foreign): egen maxp = max(price)
    -------------------------------------------------------------------------------
    Parallel Computing with Stata
    Clusters   : 2
    pll_id     : m61jt2abc1
    Running at : /home/vegayon/Dropbox/repos/parallel
    Randtype   : datetime

    Waiting for the clusters to finish...
    cluster 0001 has exited without error...
    cluster 0002 has exited without error...
    -------------------------------------------------------------------------------
    Enter -parallel printlog #- to checkout logfiles.
    -------------------------------------------------------------------------------

    . tab maxp

           maxp |      Freq.     Percent        Cum.
    ------------+-----------------------------------
          12990 |         22       29.73       29.73
          15906 |         52       70.27      100.00
    ------------+-----------------------------------
          Total |         74      100.00

Which is the \`\`parallel'' way to do:


    . sysuse auto
    (1978 Automobile Data)

    . bysort foreign: egen maxp = max(price)

    . tab maxp

           maxp |      Freq.     Percent        Cum.
    ------------+-----------------------------------
          12990 |         22       29.73       29.73
          15906 |         52       70.27      100.00
    ------------+-----------------------------------
          Total |         74      100.00

Bootstrapping
-------------

In this example we'll evaluate a regression model using bootstrapping which, together with simulations, is one of the best ways to use parallel


    . sysuse auto, clear
    (1978 Automobile Data)

    . parallel initialize 4, f
    N Clusters: 4
    Stata dir:  /usr/local/stata13/stata

    . timer on 1

    . parallel bs, reps(5000): reg price c.weig##c.weigh foreign rep
    -------------------------------------------------------------------------------
    Parallel Computing with Stata
    Clusters   : 4
    pll_id     : m61jt2abc1
    Running at : /home/vegayon/Dropbox/repos/parallel
    Randtype   : datetime

    Waiting for the clusters to finish...
    cluster 0001 has exited without error...
    cluster 0002 has exited without error...
    cluster 0003 has exited without error...
    cluster 0004 has exited without error...
    -------------------------------------------------------------------------------
    Enter -parallel printlog #- to checkout logfiles.
    -------------------------------------------------------------------------------

    parallel bootstrapping                          Number of obs      =        69
                                                    Replications       =      5000

          command:  regress price c.weig##c.weigh foreign rep

    ------------------------------------------------------------------------------
                 |   Observed   Bootstrap                         Normal-based
                 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
          weight |  -4.317581   3.033419    -1.42   0.155    -10.26297    1.627811
                 |
        c.weight#|
        c.weight |   .0012192   .0004827     2.53   0.012     .0002732    .0021653
                 |
         foreign |   3155.969   890.4385     3.54   0.000     1410.742    4901.197
           rep78 |  -30.11387   327.7725    -0.09   0.927    -672.5361    612.3084
           _cons |   6415.187   5047.099     1.27   0.204    -3476.945    16307.32
    ------------------------------------------------------------------------------

    . timer off 1

    . timer list
       1:     10.59 /        1 =      10.5930
      97:      0.07 /        2 =       0.0340
      98:      0.00 /        1 =       0.0030
      99:     10.52 /        1 =      10.5190

Which is the \`\`parallel way'' to do:


    . sysuse auto, clear
    (1978 Automobile Data)

    . timer on 2

    . bs, reps(5000) nodots: reg price c.weig##c.weigh foreign rep

    Linear regression                               Number of obs      =        69
                                                    Replications       =      5000
                                                    Wald chi2(4)       =     51.13
                                                    Prob > chi2        =    0.0000
                                                    R-squared          =    0.5622
                                                    Adj R-squared      =    0.5348
                                                    Root MSE           = 1986.4039

    ------------------------------------------------------------------------------
                 |   Observed   Bootstrap                         Normal-based
           price |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
          weight |  -4.317581   3.110807    -1.39   0.165    -10.41465    1.779489
                 |
        c.weight#|
        c.weight |   .0012192   .0004951     2.46   0.014     .0002489    .0021896
                 |
         foreign |   3155.969   863.9629     3.65   0.000     1462.633    4849.305
           rep78 |  -30.11387   323.6419    -0.09   0.926    -664.4404    604.2127
           _cons |   6415.187    5162.58     1.24   0.214    -3703.285    16533.66
    ------------------------------------------------------------------------------

    . timer off 2

    . timer list
       2:     17.78 /        1 =      17.7810

Simulation
----------

From the `simulate` stata command:


    . parallel initialize 2, f
    N Clusters: 2
    Stata dir:  /usr/local/stata13/stata

    . program define lnsim, rclass
      1.   version 12.1
      2.   syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
      3.   drop _all
      4.   set obs `obs'
      5.   tempvar z
      6.   gen `z' = exp(rnormal(`mu',`sigma'))
      7.   summarize `z'
      8.   return scalar mean = r(mean)
      9.   return scalar Var  = r(Var)
     10. end

    . parallel sim, expr(mean=r(mean) var=r(Var)) reps(10000): lnsim, obs(100)
    Warning: No data loaded.
    -------------------------------------------------------------------------------
    > -
    Exporting the following program(s): lnsim

    lnsim, rclass:
      1.   version 12.1
      2.   syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
      3.   drop _all
      4.   set obs `obs'
      5.   tempvar z
      6.   gen `z' = exp(rnormal(`mu',`sigma'))
      7.   summarize `z'
      8.   return scalar mean = r(mean)
      9.   return scalar Var = r(Var)
    -------------------------------------------------------------------------------
    > -
    -------------------------------------------------------------------------------
    Parallel Computing with Stata
    Clusters   : 2
    pll_id     : 93mwp9vps1
    Running at : /home/vegayon/Dropbox/repos/parallel
    Randtype   : datetime

    Waiting for the clusters to finish...
    cluster 0001 has exited without error...
    cluster 0002 has exited without error...
    -------------------------------------------------------------------------------
    Enter -parallel printlog #- to checkout logfiles.
    -------------------------------------------------------------------------------

    . 
    . summ

        Variable |       Obs        Mean    Std. Dev.       Min        Max
    -------------+--------------------------------------------------------
            mean |     10000    1.648843    .2165041   1.021977   2.907977
             var |     10000    4.650656    4.218584   .6159253   133.9232

which is the parallel way to do


    . program define lnsim, rclass
      1.   version 12.1
      2.   syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
      3.   drop _all
      4.   set obs `obs'
      5.   tempvar z
      6.   gen `z' = exp(rnormal(`mu',`sigma'))
      7.   summarize `z'
      8.   return scalar mean = r(mean)
      9.   return scalar Var  = r(Var)
     10. end

    . simulate mean=r(mean) var=r(Var), reps(10000) nodots: lnsim, obs(100)

          command:  lnsim, obs(100)
             mean:  r(mean)
              var:  r(V. 
    . summ

        Variable |       Obs        Mean    Std. Dev.       Min        Max
    -------------+--------------------------------------------------------
            mean |     10000    1.644006    .2133008   1.061809   2.991108
             var |     10000    4.568202    3.984818   .6348574    110.893

parfor
------

In this example we create a short program (`parfor`) which is intended to work as a `parfor` program, this is, looping through 1/N in a parallel fashion


    . // Cleaning working space
    . clear all

    . timer clear

    . 
    . // Set up
    . set seed 123

    . local n = 5e6

    . set obs `n'
    obs was 0, now 5000000

    . gen x = runiform()

    . gen y_pll = .
    (5000000 missing values generated)

    . clonevar y_ser = y_pll
    (5000000 missing values generated)

    . 
    . // Loop replacement function
    . prog def parfor
      1.         args var
      2.         forval i=1/`=_N' {
      3.                 qui replace `var' = sqrt(x) in `i'
      4.         }
      5. end

    . 
    . // Running the algorithm in parallel fashion
    . timer on 1

    . parallel initialize 4, f
    N Clusters: 4
    Stata dir:  /usr/local/stata13/stata

    . parallel, prog(parfor): parfor y_pll
    -------------------------------------------------------------------------------
    > -
    Exporting the following program(s): parfor

    parfor:
      1.         args var
      2.         forval i=1/`=_N' {
      3.                 qui replace `var' = sqrt(x) in `i'
      4.         }
    -------------------------------------------------------------------------------
    > -
    -------------------------------------------------------------------------------
    Parallel Computing with Stata
    Clusters   : 4
    pll_id     : wrusvgqb91
    Running at : /home/vegayon/Dropbox/repos/parallel
    Randtype   : datetime

    Waiting for the clusters to finish...
    cluster 0001 has exited without error...
    cluster 0002 has exited without error...
    cluster 0003 has exited without error...
    cluster 0004 has exited without error...
    -------------------------------------------------------------------------------
    Enter -parallel printlog #- to checkout logfiles.
    -------------------------------------------------------------------------------

    . timer off 1

    . 
    . // Running the algorithm in a serial way
    . timer on 2

    . parfor y_ser

    . timer off 2

    . 
    . // Is there any difference?
    . list in 1/10

         +--------------------------------+
         |        x      y_pll      y_ser |
         |--------------------------------|
      1. |  .912044   .9550099   .9550099 |
      2. | .0075452   .0868631   .0868631 |
      3. | .2808588   .5299612   .5299612 |
      4. | .4602787   .6784384   .6784384 |
      5. | .5601059   .7484022   .7484022 |
         |--------------------------------|
      6. | .6731906    .820482    .820482 |
      7. | .6177611   .7859778   .7859778 |
      8. | .8656877   .9304234   .9304234 |
      9. | 9.57e-06   .0030943   .0030943 |
     10. | .4090917   .6396028   .6396028 |
         +--------------------------------+

    . gen diff = y_pll != y_ser

    . tab diff

           diff |      Freq.     Percent        Cum.
    ------------+-----------------------------------
              0 |  5,000,000      100.00      100.00
    ------------+-----------------------------------
          Total |  5,000,000      100.00

    . 
    . // Comparing time
    . timer list
       1:      8.93 /        1 =       8.9260
       2:     16.06 /        1 =      16.0580
      97:      0.42 /        1 =       0.4240
      98:      0.32 /        1 =       0.3150
      99:      8.17 /        1 =       8.1740

    . di "Parallel is `=round(r(t2)/r(t1),.1)' times faster"
    Parallel is 1.8 times faster

    . 

Authors
=======

George G. Vega \[aut,cre\] g.vegayon %at% gmail

Brian Quistorff \[aut\] Brian.Quistorff %at% microsoft
