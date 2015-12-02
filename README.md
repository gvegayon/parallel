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

For accessing SSC version of parallel

``` stata
. ssc install parallel, replace
. mata mata mlib index
```

For accessing the latest development version of parallel (from here) using Stata version \>=13

``` stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/master/) replace
. mata mata mlib index
```

For Stata version \<13, download as zip, unzip, and then replace the above -net install- with

``` stata
. net install parallel, from(full_local_path_to_files) replace
```

Once installed it is suggested to restart Stata. If you had a previous installation of -parallel- installed from a different source you should uninstall that first.

Minimal examples
================

Simple parallelization of egen
------------------------------


    . parallel setclusters 2
    N Clusters: 2
    Stata dir:  /usr/local/stata12/stata

    . sysuse auto
    (1978 Automobile Data)

    . parallel, by(foreign): egen maxp = max(price)
    -------------------------------------------------------------------------------
    Parallel Computing with Stata (by GVY)
    Clusters   : 2
    pll_id     : 9ylrofps61
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

In this example we'll evaluate a regression model using bootstrapping


    . sysuse auto, clear
    (1978 Automobile Data)

    . parallel setclusters 4
    N Clusters: 4
    Stata dir:  /usr/local/stata12/stata

    . parallel bs, reps(1000): reg price c.weig##c.weigh foreign rep
    -------------------------------------------------------------------------------
    Parallel Computing with Stata (by GVY)
    Clusters   : 4
    pll_id     : 9ylrofps61
    Running at : /home/george/Documents/projects/parallel
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
                                                    Replications       =      1000

          command:  regress price c.weig##c.weigh foreign rep

    ------------------------------------------------------------------------------
                 |   Observed   Bootstrap                         Normal-based
                 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
          weight |  -4.317581   3.160525    -1.37   0.172     -10.5121    1.876935
                 |
        c.weight#|
        c.weight |   .0012192   .0004996     2.44   0.015       .00024    .0021984
                 |
         foreign |   3155.969    908.895     3.47   0.001     1374.568    4937.371
           rep78 |  -30.11387   324.5856    -0.09   0.926    -666.2899    606.0622
           _cons |   6415.187   5275.004     1.22   0.224    -3923.631       16754
    ------------------------------------------------------------------------------

Which is the \`\`parallel way'' to do:


    . sysuse auto, clear
    (1978 Automobile Data)

    . bs, reps(1000) nodots: reg price c.weig##c.weigh foreign rep

    Linear regression                               Number of obs      =        69
                                                    Replications       =      1000
                                                    Wald chi2(4)       =     50.72
                                                    Prob > chi2        =    0.0000
                                                    R-squared          =    0.5622
                                                    Adj R-squared      =    0.5348
                                                    Root MSE           = 1986.4039

    ------------------------------------------------------------------------------
                 |   Observed   Bootstrap                         Normal-based
           price |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
          weight |  -4.317581   3.106859    -1.39   0.165    -10.40691    1.771752
                 |
        c.weight#|
        c.weight |   .0012192   .0004976     2.45   0.014     .0002439    .0021946
                 |
         foreign |   3155.969   817.8531     3.86   0.000     1553.007    4758.932
           rep78 |  -30.11387   308.3404    -0.10   0.922    -634.4499    574.2221
           _cons |   6415.187   5140.207     1.25   0.212    -3659.434    16489.81
    ------------------------------------------------------------------------------

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
    pll_id     : cqbnotj7t1
    Running at : /home/george/Documents/projects/parallel
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
            mean |     10000    1.649657    .2139217   1.047443   2.768357
             var |     10000    4.620533    4.048313     .66248   125.2012

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

Authors
=======

George G. Vega [aut,cre] gvegayon (at) caltech dot edu

Brian Quistorff [ctb]
