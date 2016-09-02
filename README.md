PARALLEL: Stata module for parallel computing
=============================================

Parallel lets you **run Stata faster**, sometimes faster than MP itself. By organizing your job in several Stata instances, parallel allows you to work with out-of-the-box parallel computing. Using the the 'parallel' prefix, you can get **faster simulations, bootstrapping, reshaping big data**, etc. without having to know a thing about parallel computing. With **no need of having Stata/MP** installed on your computer, parallel has showed to dramatically speedup computations up to two, four, or more times depending on how many processors your computer has.

Stata conference presentation: <http://ideas.repec.org/p/boc/norl13/4.html>

SSC at Boston College: <http://ideas.repec.org/c/boc/bocode/s457527.html>

1.  [Installation](#installation)
2.  [Minimal examples](#minimal-examples)
3.  [Authors](#authors)

Installation
============
If you have a previous installation of -parallel- installed from a different source (SSC, specific folder, specific URL) you should uninstall that first. Once installed it is suggested to restart Stata. 

SSC
---

For accessing SSC version of parallel

``` stata
. ssc install parallel, replace
. mata mata mlib index
```

Development Version (Latest/Master)
--------------------------

For accessing the latest development version of parallel (from here) using Stata version \>=13

``` stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/master/) replace
. mata mata mlib index
```

For Stata version \<13, download as zip, unzip, and then replace the above -net install- with

``` stata
. net install parallel, from(full_local_path_to_files) replace
```

Development Version (Other Releases)
------------------------------------

Access other development releases via the [Releases Page](https://github.com/gvegayon/parallel/releases). You can use the release tag to install over the internet. For example,

``` stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/v1.15.8.19/) replace
. mata mata mlib index
```

Or you can download the release and install locally (for Stata \<13).

Minimal examples
================

The following minimal examples have been written to introduce how to use the module. Please notice that the only examples actually designed to show potential speed gains are [parfor](#parfor) and [bootstrap](#bootstrapping).

The examples have been executed on a Dell Vostro 3300 notebook running Ubuntu 14.04 with an Intel Core i5 CPU M 560 (2 physical cores) with 8Gb of RAM, using Stata/IC 12.1 for Unix (Linux 64-bit x86-64).

For more examples and details please refer to the module's help file.

Simple parallelization of egen
------------------------------

When conducted over groups, parallelizing `egen` can be useful. In the following example we show how to use `parallel` with `by: egen`.


    . parallel setclusters 2
    N Clusters: 2
    Stata dir:  /usr/local/stata12/stata

    . sysuse auto
    (1978 Automobile Data)

    . parallel, by(foreign): egen maxp = max(price)
    -------------------------------------------------------------------------------
    Parallel Computing with Stata (by GVY)
    Clusters   : 2
    pll_id     : rf278ev5y1
    Running at : /home/george/Documents/projects/parallel
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

    . parallel setclusters 4
    N Clusters: 4
    Stata dir:  /usr/local/stata12/stata

    . timer on 1

    . parallel bs, reps(5000): reg price c.weig##c.weigh foreign rep
    -------------------------------------------------------------------------------
    Parallel Computing with Stata (by GVY)
    Clusters   : 4
    pll_id     : rf278ev5y1
    Running at : /home/george/Documents/projects/parallel
    Randtype   : datetime
    Waiting for the clusters to finish...
    cluster 0002 has exited without error...
    cluster 0003 has exited without error...
    cluster 0004 has exited without error...
    cluster 0001 has exited without error...
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
          weight |  -4.317581   3.051228    -1.42   0.157    -10.29788    1.662716
                 |
        c.weight#|
        c.weight |   .0012192   .0004833     2.52   0.012     .0002719    .0021665
                 |
         foreign |   3155.969   878.0604     3.59   0.000     1435.002    4876.936
           rep78 |  -30.11387   322.2147    -0.09   0.926     -661.643    601.4153
           _cons |   6415.187   5086.003     1.26   0.207    -3553.196    16383.57
    ------------------------------------------------------------------------------

    . timer off 1

    . timer list
       1:     10.29 /        1 =      10.2890
      97:      0.00 /        1 =       0.0000
      98:      0.00 /        1 =       0.0000
      99:     10.22 /        1 =      10.2160

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
       2:     22.55 /        1 =      22.5530

Simulation
----------

From the `simulate` stata command:


    . parallel setclusters 2
    N Clusters: 2
    Stata dir:  /usr/local/stata12/stata

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
    Parallel Computing with Stata (by GVY)
    Clusters   : 2
    pll_id     : 2kb3dl9tl1
    Running at : /home/george/Documents/projects/parallel
    Randtype   : datetime
    Waiting for the clusters to finish...
    cluster 0002 has exited without error...
    cluster 0001 has exited without error...
    -------------------------------------------------------------------------------
    Enter -parallel printlog #- to checkout logfiles.
    -------------------------------------------------------------------------------

    . 
    . summ

        Variable |       Obs        Mean    Std. Dev.       Min        Max
    -------------+--------------------------------------------------------
            mean |     10000    1.648777    .2169697   1.002971   2.835949
             var |     10000    4.613049    3.952431   .7182144   97.69419

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

    . parallel setclusters 4
    N Clusters: 4
    Stata dir:  /usr/local/stata12/stata

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
    Parallel Computing with Stata (by GVY)
    Clusters   : 4
    pll_id     : oy6jow88d1
    Running at : /home/george/Documents/projects/parallel
    Randtype   : datetime
    Waiting for the clusters to finish...
    cluster 0002 has exited without error...
    cluster 0003 has exited without error...
    cluster 0004 has exited without error...
    cluster 0001 has exited without error...
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
       1:     15.89 /        1 =      15.8910
       2:     29.55 /        1 =      29.5500
      97:      1.03 /        1 =       1.0290
      98:      0.00 /        1 =       0.0000
      99:     14.32 /        1 =      14.3230

    . di "Parallel is `=round(r(t2)/r(t1),.1)' times faster"
    Parallel is 1.9 times faster

    . 

For more examples, see the [Gallery](https://github.com/gvegayon/parallel/wiki/Gallery).
		
Authors
=======

George G. Vega [aut,cre] gvegayon (at) caltech dot edu

Brian Quistorff [ctb]
