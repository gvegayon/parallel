*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_break.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.13.10.2  2oct2013
*! author: George G. Vega Yon


mata:
{smcl}
*! {marker parallel_break}{bf:function -{it:parallel_break}- in file -{it:parallel_break.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Stops the cluster if the mother instance has requiered so.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:parallelid}{col 20}Parallel process id. 
*!{col 6}{bf:pllinstance}{col 20}Parallel instance id.
*!{col 4}{bf:returns:}
*!{col 6}{it:Stops the cluster.}
*!{dup 78:{c -}}{asis}
void parallel_break(
    |string scalar parallelid, 
    string scalar pllinstance
    )
{
    string scalar fname, msg
    real scalar fh
    
    /* Checking empty */
    if (parallelid ==J(1,1,"")) parallelid = st_global("pll_id")
    if (pllinstance ==J(1,1,"")) pllinstance = st_global("pll_instance")
    
    /* If theres nothing to do */
    if (!strlen(parallelid+pllinstance)) return
    
    /* If the file exists: Aborting execution */
    if (fileexists(fname = sprintf("__pll%s_break", parallelid)))
    {
        /* Message */
        display(sprintf("{it:ERROR: The user has pressed -break-. Exiting}"))
        
        /* Clearing */
        stata("cap clear all")
        stata("cap clear, all")
        stata("clear")
        
        /* Opening the file and capturing the sentence */
        fh = fopen(fname, "r", 1)
        msg=fget(fh)
        fclose(fh)
        
        /* Writing the diagnosis */
        fname = sprintf("__pll%s_finito%s", parallelid, pllinstance)
        parallel_write_diagnosis(msg,fname,"User pressed break")
        
        /* Stops the execution with an error */
        _error(1)
    }
}

{smcl}
*! {marker _parallel_break}{bf:function -{it:_parallel_break}- in file -{it:parallel_break.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Stops the cluster if the mother instance has requiered so.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:parallelid}{col 20}Parallel id. 
*!{col 6}{bf:pllinstance}{col 20}Parallel instance
*!{col 4}{bf:returns:}
*!{col 6}{it:Returns -1- if the mother process has stop, else returns -0-.}
*!{dup 78:{c -}}{asis}
real scalar _parallel_break(
    |string scalar parallelid, 
    string scalar pllinstance
    )
{
    string scalar fname, msg
    real scalar fh
    
    /* Checking empty */
    if (parallelid ==J(1,1,"")) parallelid = st_global("pll_id")
    if (pllinstance ==J(1,1,"")) pllinstance = st_global("pll_instance")
    
    /* If theres nothing to do */
    if (!strlen(parallelid+pllinstance)) return(0)
    
    /* If the file exists: Aborting execution */
    if (fileexists(fname = sprintf("__pll%s_break", parallelid)))
    {        
        /* Clearing */
        stata("cap clear all")
        stata("cap clear, all")
        stata("clear")
        
        /* Opening the file and capturing the sentence */
        fh = fopen(fname, "r", 1)
        msg=fget(fh)
        fclose(fh)
        
        /* Writing the diagnosis */
        fname = sprintf("__pll%s_finito%s", parallelid, pllinstance)
        parallel_write_diagnosis(msg,fname,"User pressed break")
        
        return(1)
    }
    return(0)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_break.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_clean.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.3 18mar2014
*! author: George G. Vega

mata:

{smcl}
*! {marker parallel_clean}{bf:function -{it:parallel_clean}- in file -{it:parallel_clean.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Removes parallel auxiliry files}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:parallelid}{col 20}Parallel of the id instance.
*!{col 6}{bf:cleanall}{col 20}Whether to remove all files no matter what parallel id.
*!{col 6}{bf:force}{col 20}Forces parallel to remove files even if sandbox is working.
*!{col 4}{bf:returns:}
*!{col 6}{it:Removes all auxiliary files.}
*!{dup 78:{c -}}{asis}
void parallel_clean(|string scalar parallelid, real scalar cleanall, real scalar force, real scalar logs) {
    
    real scalar i ;
    string colvector parallelids, sbfiles;
    
    // Checking arguments
    if (parallelid == J(1,1,"")) parallelid = st_global("LAST_PLL_ID");
    if (cleanall == J(1,1,.)) cleanall = 0;
    if (force==J(1,1,.)) force = 0;
    if (logs==J(1,1,.)) logs = 0;
    
    /* Getting the list of parallel ids that should be removed */
    if (cleanall)
    {
        parallelids = dir(pwd(),"files","__pll*") \ dir(pwd(),"files","l__pll*") \ dir(pwd(),"dirs","__pll*")

        for(i=1;i<=length(parallelids);i++)
            parallelids = regexr(regexr(parallelids,"^l?__pll",""),"_.+$","")
        parallelids = uniqrows(parallelids)
    }
    else parallelids = parallelid

    
    /* Extracting files that are in use */
    if (!force) parallel_sandbox(6,"",&sbfiles)

    for(i=1;i<=length(sbfiles);i++)
        parallelids = select(parallelids, parallelids:!=sbfiles[i])

    /* Cleaning up */
    if (length(parallelids))
    {
        for(i=1;i<=length(parallelids);i++)
        {
            parallel_recursively_rm(parallelids[i],pwd(),., logs)
            parallel_recursively_rm(parallelids[i],c("tmpdir"),., logs)
        }
    }
    else display(sprintf("{text:parallel clean:} {result: nothing to clean...}"))
    
    return
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_clean.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_divide_index.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon


mata:
{smcl}
*! {marker parallel_compare_matrix}{bf:function -{it:parallel_compare_matrix}- in file -{it:parallel_divide_index.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Compares vectors and returns 1 if are equal.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:numvars}{col 20}Numeric matrix.
*!{col 6}{bf:trvars}{col 20}String matrix.
*!{col 6}{bf:i}{col 20}i-th row to compare.
*!{col 6}{bf:j}{col 20}j-th row to compare.
*!{col 4}{bf:returns:}
*!{col 6}{it:TRUE if all vector elements are equal, FALSE otherwise.}
*!{dup 78:{c -}}{asis}
real scalar parallel_compare_matrix(
    | real matrix numvars,
    string matrix strvars,
    real scalar i,
    real scalar j
    )
{
    real scalar numtest, strtest
    
    /* If any numvars, check if are equal */
    if (numvars != J(0,0,.)) numtest = all(numvars[i,]==numvars[j,]) 
    else numtest = 1

    /* If any strvars, check if are equal */
    if (strvars != J(0,0,"")) strtest = all(strvars[i,]==strvars[j,])
    else strtest = 1

    return((numtest & strtest))
}

{smcl}
*! {marker parallel_divide_index}{bf:function -{it:parallel_divide_index}- in file -{it:parallel_divide_index.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Generate index for grouping observations}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:numvars}{col 20}Numeric matrix.
*!{col 6}{bf:trvars}{col 20}String matrix.
*!{col 6}{bf:nclusters}{col 20}Number of clusters.
*!{col 4}{bf:returns:}
*!{col 6}{it:TRUE if all vector elements are equal, FALSE otherwise.}
*!{dup 78:{c -}}{asis}
real colvector parallel_divide_index(
    | real   matrix numvars,
    string matrix strvars,
    real scalar nclusters
)
{
    real scalar i, size, N, a, b, extra, before, after, nreps
    real colvector result
    
    if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
    
    /* Defining variables */
    if (numvars == J(0,0,.) & strvars == J(0,0,""))
        N = c("N")
    else if (numvars != J(0,0,.) & strvars == J(0,0,""))
        N = rows(numvars)
    else if (numvars == J(0,0,.) & strvars != J(0,0,""))
        N = rows(strvars)

    size   = J(1,1,floor(N/nclusters))
    result = J(N,1,0)
    
    /* Assigning blocks */
    if (numvars == J(0,0,.) & strvars == J(0,0,""))
    {
        /* Clean assigment */
        for(i=1;i<=nclusters;i++)
        {
            a = (i-1)*size + 1
            b = min((i*size, N))

            if (i==nclusters) result[a::N] = J(length(a::N),1,i)
            else result[a::b] = J(length(a::b),1,i)
        }
    }
    else 
    {
        /* Checking by over -numvars- */
        a = 0; b = 0
        extra  = 0
        for(i=1;i<=nclusters;i++)
        {
            a = (i-1)*size + 1 + extra
            
            /* If, from the last process, the ending is */
            if (b > a) a = b + 1
            
            b = min((i*size, N))

            /* If overlies */
            if (a > b) b = a + floor((N - a)/(nclusters - i + 1))
            
            /* If it is the last observation */
            if (i==nclusters | b>=N)
            {
                result[a::N] = J(length(a::N),1,i)
                break
            }
            else result[a::b] = J(length(a::b),1,i)
            
            /* Everything Ok? */
            before = 0
            after  = 0
            nreps  = 0
            while(parallel_compare_matrix(numvars,strvars,b,b+1))
            {
                /* Go back */
                if (a < (b + before - 1) & i < nclusters) --before
                
                if (N > (b + after + 1)) ++after
                
                if (++nreps > N) {
                    errprintf("Insufficient number of groups:\nCan not divide the dataset into -%g- clusters.\n", nclusters)
                    exit(198)
                }

                /* Checking before */
                //if (numvars[b + before,.] != numvars[b + before + 1,.])
                if(!parallel_compare_matrix(numvars,strvars,b+before,b+before+1))
                {
                    /* Moving the upper bound */
                    b = b + before
                    
                    /* Fixing next starting point */
                    extra = before
                    break
                }
                /* Checking after */
                //if (numvars[b + after ,.] != numvars[b + after + 1,.])
                if(!parallel_compare_matrix(numvars,strvars,b+after,b+after+1))
                {
                    extra = after
                    a = b
                    b = min((b + after,N))
                    result[a::b] = J(length(a::b),1,i)
                    break
                }
            }
            
            /* If no change, extra moves to 0 */
            if (before == 0 & after == 0) extra = 0

        }
    }
    
    /* Correcting biases */

    return(result)
}

end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_divide_index.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_eststore.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! parallel_estout vers 0.14 10may2014
*! auth George G Vega
mata
// mata clear
/*
 * @brief Process e() and store it as a plain-text file
 * @param stmatname Name of e()
 * @param fn File name where to save the file
 * @param fappend whether to append or replace the file
 */
{smcl}
*! {marker parallel_eststore}{bf:function -{it:parallel_eststore}- in file -{it:parallel_eststore.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
void function parallel_eststore(
    | string scalar fn,
    string scalar stlist,
    real scalar fappend
)
{
    // Variables definition
    real scalar fh, fh0
    real scalar i, j, ncol, nrow, nhead, nnewcols
    real matrix stmat, stmattmp
    string rowvector fheader, tabheader
    string matrix stcolnames0, strownames0
    string rowvector stcolnames, strownames
    real rowvector namesorder
    string scalar txt, tabs, fn0, randtype
    
    string scalar stmatname
    
    if (fappend   == J(1,1,.)) fappend = 1
    if (stlist == J(1,1,"")) stlist = "b"
    
    stmatname = "e("+stlist+")"
    
    // Matrix parsing
    stmat       = st_matrix(stmatname)
    stcolnames0 = ("","N")\st_matrixcolstripe(stmatname)
    strownames0 = ("","_"+stlist) // st_matrixrowstripe(stmatname)
    
    stmat = J(rows(stmat),1,st_numscalar("e(N)")), stmat

    // Col and row names
    stcolnames = J(1, rows(stcolnames0),"")
    for(i=1;i<=rows(stcolnames0);i++)
        for(j=1;j<=cols(stcolnames0);j++)
            stcolnames[i] = stcolnames[i]+stcolnames0[i,j]

    strownames = J(1, rows(strownames0),"")
    for(i=1;i<=rows(strownames0);i++)
        for(j=1;j<=cols(strownames0);j++)
            strownames[i] = strownames[i]+strownames0[i,j]
            
    // Merging names
    ncol = length(stcolnames)
    nrow = length(strownames)

    tabheader = J(1,nrow*ncol,"")
    
    for(i=1;i<=nrow;i++)
        for(j=1;j<=ncol;j++)
            tabheader[j + ncol*(i-1)] = strownames[i]+"_"+stcolnames[j]

    // File parsing
    if (fn == J(1,1,"")) fn = sprintf("__pll%s_eststore%04.0f.tab",st_local("pll_id"),strtoreal(st_local("pll_instance")))
    if (!fappend) unlink(fn)
    
    
    // If no such file, creat a new one
    if (!fileexists(fn))
    {
        fh = _fopen(fn, "w")
        if (fh<0) _error(1)
        
        // Writing the file header
        nhead = length(tabheader)
        txt = ""
        for(i=1;i<=nhead;i++) 
            txt = txt + tabheader[i] + 
                (i == nhead ? "" : sprintf("\t"))
        fput(fh, txt)
        
        // Writing the file lines
        for(i=1;i<=nrow;i++)
        {
            txt = ""
            for(j=1;j<=ncol;j++)
                txt = txt + sprintf("%g",stmat[i,j]) + 
                    (j==ncol? "" : sprintf("\t"))
            fput(fh, txt)
        }
                
        fclose(fh)
        
        return
    }
    else 
    {
    
        fh = _fopen(fn,"r")
        
        // Getting the order of the variables (so that we can write)
        fheader = tokens(fget(fh),sprintf("\t"))
        fclose(fh)
        fheader = select(fheader,fheader:!=sprintf("\t"))
        nhead = length(fheader)
        
        namesorder = J(1,ncol*nrow,.)
        nnewcols   = 0

        // Looking for the same varname
        for(j=1;j<=ncol*nrow;j++)
        {
            for(i=1;i<=nhead;i++)
            {
                if (fheader[i] == tabheader[j])
                {
                    namesorder[j] = i
                    break
                }
            }
            
            if (namesorder[j] == .) 
                namesorder[j] = nhead + (++nnewcols)
        }
        
        // Ordering the variables accordingly to the file
        stmattmp = J(nrow,max((max(namesorder),nhead)),.)
        for(j=1;j<=ncol;j++)
            stmattmp[,namesorder[j]] = stmat[,j]

        // In the case of new columns, the rest of the rows must be modified
        if (nnewcols)
        {
            
            fh    = fopen(fn, "r")
            fh0   = fopen(
                (fn0=parallel_randomid(10,randtype,1,1,1)), 
                "w")
            
            txt   = fget(fh)
            txt
            for(i=1;i<=length(namesorder);i++)
                if (namesorder[i]>nhead) 
                    txt = txt + sprintf("\t")+tabheader[i]
            txt
            fput(fh0,txt)
            
            tabs = ""
            for(i=1;i<=nnewcols;i++) tabs = tabs+sprintf("\t")
            
            // Adding the new lines
            while((txt=fget(fh))!=J(0,0,"") )
                fput(fh0, txt+tabs)

            // Renaming the file
            fclose(fh)
            fclose(fh0)
            stata("copy "+fn0+" "+fn+", replace")
            unlink(fn0)
        }
        
        // Writing the file lines
        fh = fopen(fn, "a")
        
        ncol = cols(stmattmp)
        
        for(i=1;i<=nrow;i++)
        {
            txt = ""
            for(j=1;j<=ncol;j++)
                txt = txt + sprintf("%g",
                    stmattmp[i,j]) + 
                    sprintf((j==ncol? "" : "\t")
                )
                
            fput(fh, txt)
        }
        
        // Finishing
        fclose(fh)        
        return
    }
}

/*
 * @brief List returning objects (scalar/macro/matrix/function)
 * @param typeofr Return type, could be e, r or s.
 */
{smcl}
*! {marker parallel_xreturnlist}{bf:function -{it:parallel_xreturnlist}- in file -{it:parallel_eststore.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
string colvector function parallel_xreturnlist(|string scalar typeofr)
{

    if (!args()) typeofr = "e"

    if (!regexm(typeofr,"^(e|r|s)$")) _error(1)

    string colvector out
    out = J(0,1,"")
    
    if (typeofr == "e") /* ereturn type */
    {
        stata("local x : e(scalars)")
        out = st_local("x")
        
        stata("local x : e(macros)")
        out = out\st_local("x")
        
        stata("local x : e(matrices)")
        out = out\st_local("x")
        
        stata("local x : e(functions)")
        out = out\st_local("x")
    }
    else if (typeofr == "r") /*return type*/
    {
        stata("local x : r(scalars)")
        out = st_local("x")
        
        stata("local x : r(macros)")
        out = out\st_local("x")
        
        stata("local x : r(matrices)")
        out = out\st_local("x")
        
        stata("local x : r(functions)")
        out = out\st_local("x")
    }
    else if (typeofr == "s") /*sreturn type*/
    {
        stata("local x : s(macros)")
        out = st_local("x")
    }
    
    return(out)
}

// General manager of parallel_estout
// Possible actions:
//  0: Start
//  1: Merge
{smcl}
*! {marker parallel_eststore_start}{bf:function -{it:parallel_eststore_start}- in file -{it:parallel_eststore.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
void function parallel_eststore_start(|string scalar fn)
{
    // Checking if the file exists
    if (args() == 0)
        fn = sprintf("__pll%s_estout%04.0f.tab",st_local("pll_id"),strtoreal(st_local("pll_instance")))
    unlink(fn)    
}

/*
 * @brief Merges parallel_estout_save() files
 * @param fn Name of the output file
 * @param fns List of file names
 * @param expr Expresion to expand in the form of "%fmts, numlist"
 */
{smcl}
*! {marker parallel_eststore_append}{bf:function -{it:parallel_eststore_append}- in file -{it:parallel_eststore.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
void parallel_eststore_append(
    string scalar fn,
    | string scalar fns,
    string scalar expr)
{

    real scalar i, nclusters
    string scalar parallelid
    string rowvector files
    
    /* If there are no arguments, ther it should be parallel using it */    
    if (args()==1) 
    {
        /* Retrieving information from parallel */
        parallelid = st_global("r(pll_id)")
        nclusters  = strtoreal(st_global("PLL_CLUSTERS"))
        
        files = J(1,nclusters,"")
        for(i=1;i<=nclusters;i++)
            files[i] = sprintf("__pll%s_eststore%04.0f.tab", parallelid, i)
    }
    else if (args() == 2) files = tokens(fns)
    else files = tokens(parallel_expand_expr(expr))
    
    if (parallelid == J(1,1,"")) parallelid = parallel_randomid(10,"",1,1,1)
    
    /* Checking which files exists */
    for(i=1;i<=length(files);i++)
    {
        if (!fileexists(files[i])) files[i] = ""
        files = select(files, files :!= "")
    }
    
    /* If no file, then exit */
    if (!length(files)) return
    
    /* Preserving information and appending the dataset */
    real scalar N
    N = c("N")
    if (N) stata("qui save __pll"+parallelid+"estout_preserve.dta, replace")
    for(i=1;i<=length(files);i++)
    {
        stata(sprintf("qui insheet using %s, clear", files[i]))
        unlink(files[i])
        if (i!=1) stata(sprintf("qui append using %s", fn))
        stata(sprintf("qui save %s, replace", fn))
    }
    
    /* Saving and compressing */
    stata("qui compress")
    stata(sprintf("save %s, replace", fn))
    
    display(sprintf("The file -%s- has been created at:{break}{tab}%s",fn,pwd()))
    
    if (N)
    {
        stata("qui use __pll"+parallelid+"estout_preserve.dta, clear")
        unlink("__pll"+parallelid+"estout_preserve.dta")
    }
    
    return
}

end

/*

local pll_instance 1
local pll_id 1asd156
local reps 100

timer clear
forval i=1/20 {
    sysuse auto, clear
    timer on 1
    qui bs, reps(`reps') : regress mpg weight c.weight#c.weight foreign
    timer off 1

    tempfile x
    save `x', replace

    timer on 2
    mata parallel_eststore_start("__pllest`i'.tab")
    forval j=1/`reps' {
        qui use `x', clear
        bsample
        qui regress mpg weight c.weight#c.weight foreign
        mata parallel_eststore("__pllest`i'.tab")
    }

    insheet using "__pllest`i'.tab", tab names clear
    qui summ
    timer off 2
}
timer list

m parallel_eststore_append("__pllest.dta","","__pllest%g.tab,1/20")

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_eststore.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_expand_expr.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.4 9apr2014
*! auth George G. Vega

 * @param 

mata:
{smcl}
*! {marker parallel_expand_expr}{bf:function -{it:parallel_expand_expr}- in file -{it:parallel_expand_expr.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Expands a fmt string combining numlists}
*!{col 4}{bf:author(s):}
*!{col 6}{it:George G. Vega}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:expr}{col 20}An expression containing a fmt and numlists
*!{col 6}{bf:pchar}{col 20}(optional) Parsing char which separates -fmt- and numlists
*!{col 4}{bf:returns:}
*!{col 6}{it:}
*!{dup 78:{c -}}{asis}
string scalar function parallel_expand_expr(
    string scalar expr,
    |string scalar pchar,
    string scalar sep
    )
{
    /* Variables definition */
    string colvector expexpr
    string scalar bexpr, out
    real scalar nexpr, i
        
    if (args()<2 | pchar==J(1,1,"")) pchar = ","
    if (args()<3) sep = " "
    
    /* Parsing the expression */
    expexpr = tokens(expr,pchar)
    expexpr = select(expexpr, expexpr :!= ",")
    if ((nexpr=length(expexpr))==1) _error(1)
        
    bexpr = expexpr[1]
    expexpr = expexpr[2..nexpr]
    nexpr = nexpr-1
    
    /* Getting the expresion */
    pointer(string rowvector) colvector numlists
    numlists = J(nexpr, 1, NULL)
    
    for(i=1;i<=nexpr;i++) 
    {
        stata(`"numlist ""'+expexpr[i]+`"""')
        numlists[i] = &tokens(st_global("r(numlist)"))
        
    }
    
    /* Creating the expression */
    real scalar i1, i2, i3, i4
    string rowvector l1, l2, l3, l4

    out = ""
    if (nexpr == 1)
    {
        l1 = *numlists[1]
        for(i1=1;i1<=length(l1);i1++)
            out = out +sep+ sprintf(bexpr,strtoreal(l1[i1]))
    }
    else if (nexpr == 2)
    {
    
        l1 = *numlists[1]
        l2 = *numlists[2]
        for(i1=1;i1<=length(l1);i1++)
            for(i2=1;i2<=length(l2);i2++)
                out = out +sep+ sprintf(bexpr,strtoreal(l1[i1]),strtoreal(l2[i2]))
    }
    else if (nexpr == 3)
    {
    
        l1 = *numlists[1]
        l2 = *numlists[2]
        l3 = *numlists[3]
        for(i1=1;i1<=length(l1);i1++)
            for(i2=1;i2<=length(l2);i2++)
                for(i3=1;i3<=length(l3);i3++)
                    out = out +sep+ sprintf(bexpr,strtoreal(l1[i1]),strtoreal(l2[i2]),strtoreal(l3[i3]))
    }
    else if (nexpr == 4)
    {
    
        l1 = *numlists[1]
        l2 = *numlists[2]
        l3 = *numlists[3]
        l4 = *numlists[4]
        for(i1=1;i1<=length(l1);i1++)
            for(i2=1;i2<=length(l2);i2++)
                for(i3=1;i3<=length(l3);i3++)
                    for(i4=1;i4<=length(l4);i4++)
                        out = out +sep+ sprintf(bexpr,strtoreal(l1[i1]),strtoreal(l2[i2]),strtoreal(l3[i3]),strtoreal(l4[i4]))
    }

    return(out)
}
end
/*
m parallel_expand_expr("%02.0f_%02.0f/mcci.dta, 2007/2013,1/12")
m parallel_expand_expr("%02.0f_%02.0f/%02.0f, 2007/2013,1/12,0/1")
m parallel_expand_expr("%02.0f_%02.0f/%02.0f, 2007/2013,1(4)12,0/1")
m parallel_expand_expr("%02.0fa%02.0fb%02.0fc%02.0fd, 1/2,3/4,5/6,7/8")
*/

/* Crear una lista de la forma 2013_01 2013_02 ... 2015_12 */
// m parallel_expand_expr("%04.0f_%02.0f, 2013/2015, 1/12")

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_expand_expr.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_export_globals.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! parallel_export_globals vers 0.14.7.23 23jul2014 @ 22:10:27
*! author: George G. Vega Yon

mata:

{smcl}
*! {marker parallel_export_globals}{bf:function -{it:parallel_export_globals}- in file -{it:parallel_export_globals.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Looks for global macros and writes to the dofile.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:outname}{col 20}Name of the new do-file.
*!{col 6}{bf:out_fh}{col 20}If a file is already open, the user can export the globals to it.
*!{col 4}{bf:returns:}
*!{col 6}{it:A do-file eady to be runned and define globals.}
*!{dup 78:{c -}}{asis}
void parallel_export_globals(|string scalar outname, real scalar ou_fh) {
    
    real   scalar isnewfile, glob_ind
    string scalar macname, macvalu, FORBIDDEN, line
    string colvector global_names

    if (outname == J(1,1,"")) outname = parallel_randomid(10,"",1,1,1)
    
    if (ou_fh == J(1,1,.)) {
        if (fileexists(outname)) unlink(outname)
        ou_fh = fopen(outname, "w", 1)
        isnewfile = 1
    }
    else isnewfile = 0

    // Step 1
    FORBIDDEN = "^(S\_FNDATE|S\_FN|F[0-9]|S\_level|S\_ADO|S\_FLAVOR|S\_OS|S\_MACH|!)"

    global_names = st_dir("global", "macro", "*")
    for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
        /* Only pic globals with a-zA-Z names */
        if (!regexm(global_names[glob_ind,1], "^[a-zA-Z]")) continue

        macname = global_names[glob_ind,1]
        if (!regexm(macname, FORBIDDEN)){
            macvalu = st_global(macname)
            line = "global "+macname+" "+macvalu
            fput(ou_fh, line)
        }
    }
    
    if (isnewfile) fclose(ou_fh)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_export_globals.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_export_programs.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.4 16apr2014
*! author: George G. Vega

mata:
{smcl}
*! {marker parallel_export_programs}{bf:function -{it:parallel_export_programs}- in file -{it:parallel_export_programs.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:export programs loaded in the current sesion.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:ouname}{col 20}Name of the file that will contain the programs.
*!{col 6}{bf:programlist}{col 20}List of programs to be exported.
*!{col 6}{bf:inname}{col 20}Name of the tmp file that will be used as log.
*!{col 4}{bf:return:}
*!{col 6}{it:A do-file ready to be runned to load programs.}
*!{dup 78:{c -}}{asis}
real scalar parallel_export_programs(
    string scalar ouname ,
    |string scalar programlist,
    string scalar inname
    ) 
    {
    
    real scalar in_fh, ou_fh
    string scalar line, oldsettrace
    string scalar pathead, patnext
    
    if (programlist==J(1,1,"")) programlist = "_all"
    if (inname==J(1,1,"")) inname = parallel_randomid(10,"",1,1,1)
    
    // Writing log
    oldsettrace =c("trace")
    if (oldsettrace == "on") stata("set trace off")
    stata("qui log using "+inname+", text replace name(plllog"+st_local("parallelid")+")")
    display(sprintf("{hline 80}{break}{result:Exporting the following program(s): %s}",programlist))
    stata("capture noisily program list "+programlist)
    stata("local err = _rc")

    real scalar err
    if ( (err = strtoreal(st_local("err"))) ) {
        stata("qui log close plllog"+st_local("parallelid"))
        stata("set trace "+oldsettrace)    
        return(err);
    }

    stata("qui log close plllog"+st_local("parallelid"))
    stata("set trace "+oldsettrace)
    
    // Opening files
    in_fh =_fopen(inname, "r")
    ou_fh =_fopen(ouname, "rw")
    
    // If any error occurs
    if (ou_fh < 0) {
        fclose(in_fh)
        return
    }
    
    fwrite(ou_fh,sprintf("\n"))
    
    // REGEX Patterns
    string scalar space
    space = "[\s ]*"+sprintf("\t")+"*"
    pathead = "^"+"[^0-9][a-zA-Z_]+([a-zA-Z0-9_]*)(,"+space+"[a-zA-Z]*)?[:]"+space+"$"
    patnext = "^[>] "
    
    while ((line = fget(in_fh))!=J(0,0,"")) {
        
        // Enters if it is a start of a program
        if(regexm(line, pathead)) {
            // Writes the header
            fput(ou_fh, sprintf("program def %s", subinstr(line, ":", "")))
            line = fget(in_fh)
        
            // While it is whithin the program
            while (line!=J(0,0,"")) {
                 // If it is a trimmed version of the program
                if (regexm(line, patnext)) {
                    fwrite(ou_fh, regexr(line, patnext,""))
                }
                // If it is the last line of the program
                else if (strlen(line) == 0) {
                    fput(ou_fh, sprintf("\nend"))
                    break
                }
                else { // If it is ok
                    line = regexr(line, "^[\s ]*[0-9]+\.", "")
                    fwrite(ou_fh, strltrim(sprintf("\n%s",line)))
                }
                line = fget(in_fh)
            }
        }
    }
    
    // Cleaning the files
    fclose(in_fh)
    unlink(inname)
    fwrite(ou_fh,sprintf("\nend\n"))
    fclose(ou_fh)
    display("{hline 80}")
    return(0)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_export_programs.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_finito.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.14.7.22  22jul2014
*! author: George G. Vega Yon

mata:
{smcl}
*! {marker parallel_finito}{bf:function -{it:parallel_finito}- in file -{it:parallel_finito.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Waits until every process finishes or stops the processes}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:parallelid}{col 20}Parallel instance id.
*!{col 6}{bf:nclusters}{col 20}Number of clusters.
*!{col 6}{bf:timeout}{col 20}Time (in secs) before abort.
*!{col 4}{bf:returns:}
*!{col 6}{it:Number of clusters that stopped with error.}
*!{dup 78:{c -}}{asis}
real scalar parallel_finito(
    string scalar parallelid,
    | real scalar nclusters,
    real scalar timeout
    )
    {
    
    display(sprintf("{it:Waiting for the clusters to finish...}"))
    
    // Setting default parameters
    if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
    if (timeout == J(1,1,.)) timeout = 6000
    
    // Variable definitios
    real scalar in_fh, out_fh, time
    real scalar suberrors, i, errornum, retcode
    string scalar fname
    string scalar msg
    real scalar bk, pressed
    real rowvector pendingcl
    
    // Initial number of errors
    suberrors = 0
    
    /* Temporaly sets break key off */
    /* In windows (by now) parallel cannot use the breakkey */
    bk=querybreakintr();
    if (c("os")!="Windows") 
    {
        bk = setbreakintr(0)
        pressed=0
    }
    
    /* Checking conextion timeout */
    pendingcl = J(1,0,.)
    for(i=1;i<=nclusters;i++)
    {        
        /* Building filename */
        fname = sprintf("__pll%s_do%04.0f.log", parallelid, i)
        time = 0
        while (!fileexists(fname) & ((++time)*100 < timeout) & !breakkey())
            stata("sleep 100")
            
        if (!fileexists(fname))
        {
            display(sprintf("{it:cluster %04.0f} {text:has finished with a connection error -601- (timeout) ({stata search r(601):see more})...}", i))
            suberrors++
            continue
        }
        else pendingcl = pendingcl, i
            
        timeout = timeout - time*100
    }
    
    /* If there are as many errors as clusters, then exit */
    if (suberrors == nclusters) return(suberrors)
    
    string scalar logfilename, tmpdirname

    while(length(pendingcl)>0)
    {
        
        // Building filename
        for (i=1;i<=nclusters;i++)
        {
            /* If this cluster is ready, then continue */
            if (!any(pendingcl :== i)) continue
            
            fname = sprintf("__pll%s_finito%04.0f", parallelid, i)
            
            if (breakkey() & !pressed) 
            { /* If the user pressed -break-, each instance will try to finish the work through parallel finito */
                /* Message */
                display(sprintf("{it:The user pressed -break-. Trying to stop the clusters...}"))
            
                /* Openning and checking for the new file */
                fname = sprintf("__pll%s_break", parallelid)
                if (fileexists(fname)) _unlink(fname)
                out_fh = fopen(fname, "w", 1)
                
                /* Writing and exit */
                fput(out_fh, "1")
                fclose(out_fh)
                
                pressed = 1
                fname = sprintf("__pll%s_finito%04.0f", parallelid, i)
                
            }
        
            if (fileexists(fname)) // If the file exists
            {
                /* Opening the file and looking for somethign different of 0
                (which is clear) */

                /* Copying log file */
                logfilename = sprintf("%s__pll%s_do%04.0f.log", (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/"), parallelid, i)
                stata(sprintf(`"cap copy __pll%s_do%04.0f.log "%s%s", replace"', parallelid, i, c("tmpdir"),logfilename))
                retcode = _unlink(pwd()+logfilename)
                /* Sometimes Stata hasn't released the file yet. Either way, don't error out  */
                if (retcode !=0){
                    stata("sleep 2000")
                    _unlink(pwd()+logfilename)
                }

                in_fh = fopen(fname, "r", 1)
                if ((errornum=strtoreal(fget(in_fh))))
                {
                    msg = fget(in_fh)
                    if (msg == J(0,0,"")) display(sprintf(`"{it:cluster %04.0f} {text:Exited with error -%g- ({stata parallel viewlog %g, e(%s):view log})...}"', i, errornum, i, parallelid))
                    else display(sprintf(`"{it:cluster %04.0f} {text:Exited with error -%g- %s ({stata parallel viewlog %g, e(%s):view log})...}"', i, errornum, msg, i, parallelid))
                    suberrors++
                }
                else display(sprintf("{it:cluster %04.0f} {text:has exited without error...}", i))
                fclose(in_fh)

                /* Checking tmpdir */
                tmpdirname = sprintf("%s"+ (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/") + "__pll%s_tmpdir%04.0f", c("tmpdir"),parallelid,i)
                parallel_recursively_rm(parallelid,tmpdirname,1)
                rmdir(tmpdirname)
                
                /* Taking the finished cluster out of the list */
                pendingcl = select(pendingcl, pendingcl :!= i)
                
                continue
            } /* Else just wait for it 1/10 of a second! */
            else stata("sleep 100")
        }
    }
    
    /* Returing to old break value */
    if (querybreakintr()!=bk) 
    {
        breakkeyreset()
        (void) setbreakintr(bk)
    }
    
    real scalar linesize
    linesize = c("linesize") > 80 ? 80 : c("linesize")
    display(sprintf("{hline %g}{break}{text:Enter -{stata parallel printlog 1, e(%s):parallel printlog #}- to checkout logfiles.}{break}{hline %g}", linesize, parallelid, linesize))
    
    return(suberrors)
    
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_finito.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_for.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
cap mata: mata drop parallel_for()
mata:
{smcl}
*! {marker parallel_for}{bf:function -{it:parallel_for}- in file -{it:parallel_for.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
void parallel_for(real matrix data, string scalar fun, | real scalar byrow) {
    
    real scalar i, obsleft, clsize, nobs
    real rowvector sizes
    
    // Setting how many obs should be
    if (byrow == J(1,1,.)) byrow = 1
    
    if (byrow) nobs = rows(data)
    else nobs = cols(data)
    
    clsize  = round(nobs/4)
    obsleft = nobs
    sizes = J(1,0,.)
    while ((obsleft = (obsleft - clsize)) > 0) {
        sizes = sizes, clsize
    }
    
    if ((obsleft = nobs - sum(sizes)) > 0) sizes = sizes, obsleft
    
    fun = sprintf("mata:\nfor(i=1;i<=%g;i++) {\n\t%s\n}\nend",rows(data), fun)
    parallel_write_do(fun, "123123", 4)
}
end

parallel clean, all
mata: parallel_for(J(50,2,1),"sum[1..i]")
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_for.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_montecarlo.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
mata

// Resampling algorithm
{smcl}
*! {marker parallel_resample}{bf:function -{it:parallel_resample}- in file -{it:parallel_montecarlo.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
real colvector function parallel_resample(
        | real scalar size,
        real colvector weights
        )
{
        real colvector permut, index, newsample
        real scalar N0, N1, n, i, k, j

        N0 = c("N")

        // Getting the sample size
        if (size < 1) n = max( (1,round(size*N0)) )
        else {
        if (N0 < size)
        {
            printf("N is smaller than the requiered size\n")
            n = N0
        }
        else n = size
    }

        // Expanding the observations index (or not!)
    k = 0
        if (weights != J(0,1,.))
        {
        N1 = sum(weights)
                index = J(sum(weights),1,1)
                for(i=1;i<=N0;i++)
                {
                        j=0
                        while(j++ < weights[i])
                                index[++k] = i
                }
        }
        else
    {
        N1 = N0
        index = 1::N0
    }

    index = index\index

    // Getting the selected obs id
        permut = index[order(runiform(N1*2,1),1)[1::n]]

    // Creating the weights
    newsample = J(N0,1,0)
    for(i=1;i<=n;i++)
        newsample[permut[i]] = newsample[permut[i]] + 1
        

    return(newsample)

}

end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_montecarlo.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_normalizepath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.4 18apr2014
*! author: George G. Vega Yon


mata:
{smcl}
*! {marker parallel_normalizepath}{bf:function -{it:parallel_normalizepath}- in file -{it:parallel_normalizepath.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Path parsing.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:Path}{col 20}to be analized.
*!{col 6}{bf:Whether}{col 20}to export the results as local or not.
*!{col 4}{bf:return:}
*!{col 6}{it:A vector with path\fullpath\fileext\filename. }
*!{dup 78:{c -}}{asis}
transmorphic function parallel_normalizepath(
    string scalar path,
    | real scalar exportaslocal
    )
    {
    
    string scalar filename, fileext, fullpath, filedir, curpath
    string rowvector parts
    real scalar i, isfile
    
    if (exportaslocal == J(1,1,.)) exportaslocal = 0
        
    // Replacing folder sep
    fullpath = subinstr(path, "\", "/")
    fullpath = subinstr(path, `"""', "")
    
    // Verifying if there is anything
    if (fileexists(fullpath)) isfile = 1
    else if (direxists(fullpath)) isfile = 0
    else _error(601)
    
    curpath = regexr(pwd(), "/$", "")
    
    if (isfile) {
        if(fileexists(pwd()+fullpath))
            fullpath = subinstr(pwd(),"\","/")+fullpath
    }
    else {
        if(direxists(pwd()+fullpath))
            fullpath = subinstr(pwd(),"\","/")+fullpath
    }
    
    // Cleaning ".." and spliting (parsing)
    parts = tokens(fullpath,"/")
    if (cols(parts) >= 3) {
        for(i=3;i<=cols(parts);i++) {
            if (parts[i] == "..") parts[(i-2)..i] = J(1,3,"")
        }
    }
    
    // Merging all
    fullpath = ""
    for(i=1;i<=cols(parts);i++) fullpath = fullpath+parts[i]
    
    // Replacing "//"
    while (strlen(fullpath) != strlen(regexr(fullpath, "//", "/")))
        fullpath = regexr(fullpath, "//", "/")
    
    // Last check
    if (isfile) {
        if(!fileexists(fullpath)) _error(1)
    }
    else {
        if(!direxists(fullpath)) _error(1)
    }
    
    // Extracting details
    pathsplit(fullpath, filedir, filename)
    fileext = pathsuffix(filename)
    
    /* Checking last-bar */
    if (!regexm(filedir,"(\/|\\)$")) filedir = filedir+"/"
        
    if (exportaslocal) {
        st_local("filedir",filedir)
        st_local("filename",filename)
        st_local("fullpath",fullpath)
        st_local("fileext",fileext)
    }
    else  return((path\fullpath\fileext\filename))
    
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_normalizepath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_randomid.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 1.14.5 06may2014
*! author: George G. Vega Yon

mata:
{smcl}
*! {marker parallel_randomid}{bf:function -{it:parallel_randomid}- in file -{it:parallel_randomid.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Mata's Random id generation.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:n}{col 20}Number of random ids to generate.
*!{col 6}{bf:randtype}{col 20}Type of random algorithm to use.
*!{col 6}{bf:alpha}{col 20}Whether to use or not alphanum.
*!{col 6}{bf:nele}{col 20}Length of each random id generated.
*!{col 6}{bf:ilent}{col 20}Whether to run quietly or not.
*!{col 4}{bf:returns:}
*!{col 6}{it:String colvector of random ids.}
*!{dup 78:{c -}}{asis}
string colvector parallel_randomid(|real scalar n, string scalar randtype, real scalar alpha, real scalar nele, real scalar silent) {
    
    string scalar curseed
    string scalar newseed, tmpid
    string scalar line
    string vector id, id2
    real scalar rn_fh, i, j
    
    id = J(0,1,"")
    
    if (alpha == J(1,1,"")) alpha = 1
    if (nele == J(1,1,.)) nele = 1
    if (silent == J(1,1,.)) silent = 0
    
    // Checking if randtype is supported
    if (!regexm(randtype,"^(current|random.org|datetime)$") & strlen(randtype) > 0) {
        errprintf("randtype -%s- not supported\nPlease try with -random.org- or -datetime-\n", randtype)
        exit(198)
    }
    
    // Parsing id length
    if (n==J(1,1,.)) n = 10
    
    // Keeping the current seed value (if its going to change)
    if (randtype!=J(1,1,"")) curseed = c("seed")

    /* Checking whether PLL has already used an ID */
    if (!strlen(st_global("PLL_LASTRNG"))) st_global("PLL_LASTRNG","0")
    
    real scalar PLL_LASTRNG
    PLL_LASTRNG = strtoreal(st_global("PLL_LASTRNG")) + 1
    st_global("PLL_LASTRNG", strofreal(PLL_LASTRNG))

    n = n - strlen(strofreal(PLL_LASTRNG))
    
    if (randtype=="random.org") {
        if (!silent) printf("Connecting to random.org API...")
        if (alpha) { /* Gets strings */
            rn_fh = _fopen("http://www.random.org/strings/?num="+strofreal(nele)+"&len="+strofreal(n)+"&digits=on&upperalpha=off&loweralpha=on&unique=on&format=plain&rnd=new","r")
        }
        else {       /* Gets integers */
            rn_fh = _fopen("http://www.random.org/integers/?num="+strofreal(nele)+"&min="+ strofreal(10^(n))+"&max="+strofreal(10^(n+1)-1)+"&col=1&base=10&format=plain&rnd=new", "r")
        }
        
        if (rn_fh >= 0) { // If the connection works fine
            id = J(0,1,"")
            while ((line=fget(rn_fh)) != J(0,0,"") ) {
                id = id\ line+strofreal(PLL_LASTRNG)
            }
            fclose(rn_fh)
            if (!silent) printf("success!\n")
            
            // Returns the random id from random.org
            for(i=1;i<=nele;i++) {
                if (!silent) display(sprintf("Your random id is {ul:%s} (saved in {stata return list:r(id"+strofreal(i)+")})\n", id[i]))
                st_global("r(id"+strofreal(i)+")", id[i])
            }
            return(id)
            
        }
        else { // If the connection does not work
            errprintf("Can not connect to -random.org-\n")
            exit(rn_fh)
        }
    }
    else if (randtype=="datetime") {
        newseed = strtrim(sprintf("%15.0f",
            sum(ascii(c("current_date")))+ /* Date component */
            sum(ascii(c("user")))+         /* Usr name component */
            strtoreal(strreverse(subinstr(c("current_time"),":","")))) /* Time component */
            )
        stata("set seed "+newseed)
    }
    
    if (alpha) id2 = (tokens(c("alpha")), strofreal(1..9),tokens(c("alpha")), strofreal(1..9)    )
    else id2 = strofreal(1..9),strofreal(1..9),strofreal(1..9),strofreal(1..9)

    for(j=1;j<=nele;j++) {
        id2 = jumble(id2')'
        tmpid = ""        
        for(i=1;i<=n;i++) {
            tmpid = tmpid+id2[i]
        }
        id = id\tmpid+strofreal(PLL_LASTRNG)
    }
    
    if (randtype!=J(1,1,"")) stata("set seed "+curseed)
    
    // Returns the random id
    for(i=1;i<=nele;i++) {
        if (!silent) display(sprintf("Your random id is {ul:%s} (saved in {stata return list:r(id"+strofreal(i)+")})\n", id[i]))
        st_global("r(id"+strofreal(i)+")", id[i])
    }
    
    return(id)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_randomid.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_recursively_rm.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}

mata

/*
 *@brief Recursively removes parallel tmpfiles
 *@param parallelid Id of the parallel process to clean
 *@param path Path where to search for auxiliary files
 */
{smcl}
*! {marker parallel_recursively_rm}{bf:function -{it:parallel_recursively_rm}- in file -{it:parallel_recursively_rm.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}{asis}
void function parallel_recursively_rm(string scalar parallelid ,| string scalar path, real scalar atomic, real scalar rmlogs)
{
    if (path==J(1,1,"")) path = pwd()
    else if (!regexm(path,"[/\]$")) path = path+"/"

    // display("{hline}{break}Entering folder "+path)
    
    if (atomic == J(1,1,.)) atomic = 0
    if (rmlogs == J(1,1,.)) rmlogs = 0
    
    string scalar pattern
    if (!atomic) pattern = "__pll"+parallelid+"_*"
    else pattern = "*"

    string colvector dirs
    string colvector files

    /* Listing files */
    dirs  = dir(path,"dirs",pattern,1)
    files = dir(path,"files",pattern,1)\dir(path,"files","l"+pattern,1)
    
    real scalar i
    if (atomic)
    {
        for(i=1;i<=length(files);i++)
            unlink(files[i])
    }
    else
    {
        /* We don't want to remove logfiles in tmpdir */
        for(i=1;i<=length(files);i++)
            if ( !regexm(files[i],"do[0-9]+\.log$") | rmlogs)
                unlink(files[i])
    }

    /* Entering each folder */
    for(i=1;i<=length(dirs);i++)
        parallel_recursively_rm(parallelid, dirs[i], 1)

    /* Removing empty folders */
    for(i=1;i<=length(dirs);i++)
        rmdir(dirs[i])


    return
}

end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_recursively_rm.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_run.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.14.7.22 22jul2014
*! author: George G. Vega Yon


mata:
{smcl}
*! {marker parallel_run}{bf:function -{it:parallel_run}- in file -{it:parallel_run.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Runs parallel clusters in batch mode.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:parallelid}{col 20}Parallel id.
*!{col 6}{bf:nclusters}{col 20}Number of clusters.
*!{col 6}{bf:paralleldir}{col 20}Dir where the process should be running.
*!{col 6}{bf:timeout}{col 20}Number of seconds to wait until stop the process for no conextion.
*!{col 6}{bf:gateway_fname}{col 20}Name of file that a Cygwin process is listen to will execute from (Windows batch).
*!{col 4}{bf:returns:}
*!{col 6}{it:Number of clusters that stopped with an error.}
*!{dup 78:{c -}}{asis}
real scalar parallel_run(
    string scalar parallelid, 
    |real scalar nclusters, 
    string scalar paralleldir,
    real scalar timeout,
    string scalar gateway_fname
    ) {

    real scalar fh, i
    string scalar tmpdir_i
    
    // Setting default parameters
    if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
    if (paralleldir == J(1,1,"")) paralleldir = st_global("PLL_STATA_PATH")
    
    // Message
    display(sprintf("{hline %g}",c("linesize") > 80?80:c("linesize")))
    display("{result:Parallel Computing with Stata} (by GVY)")
    display("{text:Clusters   :} {result:"+strofreal(nclusters)+"}")
    display("{text:pll_id     :} {result:"+parallelid+"}")
    display("{text:Running at :} {result:"+c("pwd")+"}")
    display("{text:Randtype   :} {result:"+st_local("randtype")+"}")

    string scalar tmpdir
    tmpdir = c("tmpdir") + (regexm(c("tmpdir"),"(/|\\)$") ? "" : "/")
    
    if (c("os") != "Windows") { // MACOS/UNIX
        unlink("__pll"+parallelid+"_shell.sh")
        fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)

        // Writing file
        if (c("os") != "Unix") {
            for(i=1;i<=nclusters;i++) {
                mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
                fput(fh, "export STATATMP="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f"))
                fput(fh, paralleldir+`" -e -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
            }
        }
        else {
            for(i=1;i<=nclusters;i++) {
                mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1) // fput(fh, "mkdir "+c("tmpdir")+"/__pll"+parallelid+strofreal(i,"%04.0f"))
                fput(fh, "export STATATMP="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f"))
                fput(fh, paralleldir+`" -b -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
            }
        }

        fclose(fh)
        
        // stata("shell sh __pll"+parallelid+"shell.sh&")
        stata("winexec sh __pll"+parallelid+"_shell.sh")
    }
    else { // WINDOWS
        if (c("mode")=="batch"){ //Execute commands via Cygwin process
            if (gateway_fname == J(1,1,"")) gateway_fname = st_global("PLL_GATEWAY_FNAME")
            fh = fopen(gateway_fname,"a", 1)
            for(i=1;i<=nclusters;i++) {
                tmpdir_i = tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f")
                mkdir(tmpdir_i,1) // fput(fh, "mkdir "+c("tmpdir")+"/"+parallelid+strofreal(i,"%04.0f"))
                fput(fh, `"export STATATMP=""'+tmpdir_i+`"""')
                fput(fh, paralleldir+`" -e -q do ""'+pwd()+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do" &"')
            }
            fclose(fh)
        }
        else{
            unlink("__pll"+parallelid+"_shell.bat")
            fh = fopen("__pll"+parallelid+"_shell.bat","w", 1)
            
            fput(fh, "pushd "+pwd())

            // Writing file
            for(i=1;i<=nclusters;i++) {
                mkdir(tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i, "%04.0f"),1)
                fwrite(fh, "start /MIN /HIGH set STATATMP="+tmpdir+"__pll"+parallelid+"_tmpdir"+strofreal(i,"%04.0f")+" ^& ")
                fput(fh, paralleldir+`" /e /q do ""'+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+`".do"^&exit"')
            }
            
            fput(fh, "popd")
            fput(fh, "exit")
            
            fclose(fh)
            
            stata("winexec __pll"+parallelid+"_shell.bat")
        }
    }
    
    /* Waits until each process ends */
    return(parallel_finito(parallelid,nclusters,timeout))
}
end


*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_run.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_sandbox.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.4 17apr2014
 *               another parallel process).
mata:
{smcl}
*! {marker parallel_sandbox}{bf:function -{it:parallel_sandbox}- in file -{it:parallel_sandbox.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Set of tools to prevent parallel instances to overlap.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:action}{col 20}Action to be taken.
*!{col 6}{bf:pll_id}{col 20}Parallel process id.
*!{col 6}{bf:result}{col 20}Pointer to list of files that can be removed (without stopping
*!{col 4}{bf:returns:}
*!{col 6}{it:Depends on the action.}
*!{dup 78:{c -}}{asis}
void parallel_sandbox(
    real scalar action,   /* 
        0: Check and create, if error aborts with error ;
        1: Returns a list of files that can be erased 
        2: Delets the respective sandbox file 
        3: Updates the status of a sandbox file
        4:
        5: Retrieves a parallelid as a scalar
        6: Retrieves a list of parallelids that have a sandboxfile
        */
    |string scalar pll_id,
    pointer(scalar) scalar result
    )
{
    /* Definign variables */
    real scalar fh,i;
    string scalar tmpdir
    string colvector sbids, sbfnames;
    
    tmpdir = c("tmpdir")+(c("os") != "Windows" ? "/" : "")

    /* Checks if a parallel instance is currently running with the same pll id name */
    if (action==0)
    {
        /* Checking if the files exist */
        if (fileexists(tmpdir+"__pll"+pll_id+"_sandbox"))
            _error(912,sprintf("-%s- aldready in use. Please change the seed.", pll_id))
        
        /* Creating the new file */
        fh = fopen(tmpdir+"__pll"+pll_id+"_sandbox", "w");
        fput(fh,"pll_id:"+pll_id);
        fput(fh,"date:"+c("current_date")+" "+c("current_time"))
        fput(fh,"usr:"+c("username"))
        fclose(fh);
        
        return
    }
    
    /* Returns a list of files which are not intended to be erased */
    string scalar sbidsi
    if (action==1)
    {
        /* Listing the files that shuldn't be removed */
        sbids = dir(tmpdir,"files","__pll*sandbox",1);
        
        sbfnames = J(0,1,"");
        
        if (length(sbids))
        {
            for(i=1;i<=length(sbids);i++)
            {
                if (regexm(sbids[i],"[_][_]pll(.+)[_]sandbox$"))
                {
                    sbidsi = regexs(1); // regexr(sbids[i], "__pll", ""), "_.*", "");
                    sbfnames = sbfnames\dir(pwd(),"files","__pll"+sbidsi+"*",1)\tmpdir+sbids[i];
                }
            }
        }

        /* Assigning the value */
        (*result) = sbfnames
        
        return
    }
    
    /* Removes the corresponding file to be removed */
    if (action==2)
    {
        unlink(tmpdir+"__pll"+pll_id+"_sandbox")
        return
    }

    /* Updates the status of a parallel instance
    if (action==3)
    {
        fh = fopen("__pll"+pll_id+"_sandbox","rw");
        fseek(fh,2);
        fput(fh,"date:"+c("current_date")+" "+c("current_time"));
        fclose(fh);
        
        return
    } */

    if (action==4)
    {
        /* Listing the folders that shouldn't be removed */
        sbids = dir(tmpdir,"files","__pll*sandbox");
        
        sbfnames = J(0,1,"");

        if (length(sbids))
        {
            for(i=1;i<=length(sbids);i++)
            {
                if (regexm(sbids[i],"[_][_]pll(.+)[_]sandbox$"))
                {
                    sbidsi = regexs(1); // regexr(sbids[i], "__pll", ""), "_.*", "");
                    sbfnames = sbfnames\dir(pwd(),"dirs","__pll"+sbidsi+"*",1)
                }
            }
        }

        /* Assigning the value */
        (*result) = sbfnames

        return

    }
    
    if (action==5)
    {
        real scalar idtaken
        idtaken=1
        while(idtaken)
        {
            pll_id = parallel_randomid(10, "datetime", 1, 1, 1)
            idtaken    = fileexists(tmpdir+"__pll"+pll_id+"sandbox")
        }
        
        /* Securing the pllid */
        parallel_sandbox(0, pll_id)
        st_local("parallelid", pll_id)
        
        return
    }
    
    if (action == 6)
    {
        sbids = dir(tmpdir,"files","__pll*sandbox");
        for(i=1;i<=length(sbids);i++)
            sbids[i] = regexr(regexr(sbids[i],"^__pll",""),"sandbox$","")
            
        /* Assigning the value */
        (*result) = sbfnames
    }
    
}
end

/*
run ado/parallel_clean.mata

mata:
// x=""
parallel_sandbox(2,"cdaozjzrqn")
parallel_sandbox(0,"cdaozjzrqn")
parallel_sandbox(1,"" ,&(x=""))
x
stata("ls")

end
cp __pllcdaozjzrqn_sandbox __pllcdaozjzra_data1.dta, replace
cp __pllcdaozjzrqn_sandbox __pllcdaozjzrqn_data1.dta, replace
ls
mata parallel_clean2("",1)
ls
mata parallel_sandbox(2,"cdaozjzrqn")
mata parallel_clean2("",1)
ls

*/

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_sandbox.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_setclusters.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon

mata:
{smcl}
*! {marker parallel_setclusters}{bf:function -{it:parallel_setclusters}- in file -{it:parallel_setclusters.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Initial cluster setup for parallel.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:ncluster}{col 20}Number of clusters.
*!{col 6}{bf:force}{col 20}Whether to force setting more than 8 clusters.
*!{col 4}{bf:returns:}
*!{col 6}{it:A global PLL_CLUSTERS.}
*!{dup 78:{c -}}{asis}
void parallel_setclusters(real scalar nclusters, |real scalar force) {
        
    // Setting number of clusters
    if (force == J(1,1,.)) force = 0
    if (nclusters <= 8 | (nclusters > 8 & force)) {
        st_global("PLL_CLUSTERS", strofreal(nclusters))
    }
    else _error(912,`"Too many clusters: If you want to set more than 8 clusters you should use the option -force-"')
    display(sprintf("{text:N Clusters}: {result:%g}",nclusters))
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_setclusters.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_setstatapath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.14.7 22jul2014
*! author: George G. Vega Yon


mata:
{smcl}
*! {marker parallel_setstatapath}{bf:function -{it:parallel_setstatapath}- in file -{it:parallel_setstatapath.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Sets the path where stata exe is installed.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:tatadir}{col 20}If the user wants to set it manually
*!{col 6}{bf:force}{col 20}Avoids path checking.
*!{col 4}{bf:returns:}
*!{col 6}{it:A global PLL_STATA_PATH.}
*!{dup 78:{c -}}{asis}
real scalar parallel_setstatapath(string scalar statadir, | real scalar force) {

    string scalar bit, flv, fname, sys_dir

    // Is it 64bits?
    if (c("osdtl") != "" | c("bit") == 64) bit = "-64"
    else bit = ""
    
    // Building fullpath name
    if (statadir == J(1,1,"") | statadir == "") {
        if (c("os") == "Windows") { // WINDOWS
            if (c("MP")) flv = "MP"
            else if (c("SE")) flv = "SE"
            else if (c("flavor") == "Small") flv = "SM"
            else if (c("flavor") == "IC") flv = ""
        
            /* If the version is less than eleven */
            if (c("stata_version") < 11) fname = "w"+flv+"Stata.exe"
            else fname = "Stata"+flv+bit+".exe"
            
            statadir = c("sysdir_stata") + fname
            
            //might need to convert to cygwin path-name
            if (c("mode")=="batch"){
                if (!force) if (!fileexists(statadir)) return(601)
                statadir = "/cygdrive/"+substr(c("sysdir_stata"),1,1)+"/"+substr(c("sysdir_stata"),4,.) + fname
                force=1
            }
            
        }
        else if (regexm(c("os"), "^MacOS.*")) { // MACOS
        
            if (c("stata_version") < 11 & (c("osdtl") != "" | c("bit") == 64)) bit = "64"
            else bit = ""
        
            if (c("MP")) flv = "Stata"+bit+"MP" 
            else if (c("SE")) flv = "Stata"+bit+"SE"
            else if (c("flavor") == "Small") flv = "smStata"
            else if (c("flavor") == "IC") flv = "Stata"+bit
            
            statadir = c("sysdir_stata")+flv+".app/Contents/MacOS/"+flv
        }
        else { // UNIX
            if (c("MP")) flv = "stata-mp" 
            else if (c("SE")) flv = "stata-se"
            else if (c("flavor") == "Small") flv = "stata-sm"
            else if (c("flavor") == "IC") flv = "stata"
        
            statadir = c("sysdir_stata")+flv
        }
    }

    // Setting PLL_STATA_PATH
    if (force == J(1,1,.)) force = 0
    if (!force) if (!fileexists(statadir)) return(601)
    
    if (!regexm(statadir, `"^["]"')) st_global("PLL_STATA_PATH", `"""'+statadir+`"""')
    else st_global("PLL_STATA_PATH", statadir)
    
    display(sprintf("{text:Stata dir:} {result: %s}" ,statadir))
    return(0)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_setstatapath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_write_diagnosis.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.13.09.30  30sep2013
*! author: George G. Vega Yon

mata:
{smcl}
*! {marker parallel_write_diagnosis}{bf:function -{it:parallel_write_diagnosis}- in file -{it:parallel_write_diagnosis.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Writes a diagnosis to be read by -parallel_finito()-}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:diagnosis}{col 20}Text to be written.
*!{col 6}{bf:fname}{col 20}File where to write the diagnosis.
*!{col 6}{bf:msg}{col 20}Message to include at the end of the file.
*!{col 4}{bf:returns:}
*!{col 6}{it:A file with one or two lines.}
*!{dup 78:{c -}}{asis}
void parallel_write_diagnosis(
    string scalar diagnosis,
    string scalar fname,
    | string scalar msg
) 
{
    real scalar fh
    if (fileexists(fname)) unlink(fname)
    fh = fopen(fname, "w")
    fput(fh, diagnosis)
    fput(fh, msg)
    fclose(fh)
    
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_write_diagnosis.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_write_do.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.14.7.22  22jul2014
* Generates the corresponding dofiles

mata:
{smcl}
*! {marker parallel_write_do}{bf:function -{it:parallel_write_do}- in file -{it:parallel_write_do.mata}-}
*! {back:{it:(previous page)}}
*!{dup 78:{c -}}
*!{col 4}{it:Writes a fully functional do-file to be runned by -parallel_run()-.}
*!{col 4}{bf:parameters:}
*!{col 6}{bf:inputname}{col 20}Name of a do-file or string with a commando to be runned.
*!{col 6}{bf:parallelid}{col 20}Parallel instance ID.
*!{col 6}{bf:ncluster}{col 20}Number of clusters (files).
*!{col 6}{bf:prefix}{col 20}Whether this is a command (prefix != 0) or a do-file.
*!{col 6}{bf:matsave}{col 20}Whether to include or not MATA objects.
*!{col 6}{bf:getmacros}{col 20}Whete to include or not Globals.
*!{col 6}{bf:eed}{col 20}Seed to be used (list)
*!{col 6}{bf:randtype}{col 20}If no seeds provided, type of algorithm used to generate the seeds
*!{col 6}{bf:nodata}{col 20}Wheter to load (1) data or not.
*!{col 6}{bf:folder}{col 20}Folder where the do-file should be running.
*!{col 6}{bf:programs}{col 20}A list of programs to be used within each cluster.
*!{col 6}{bf:processors}{col 20}Number of statamp processors to use in each cluster.
*!{col 4}{bf:returns:}
*!{col 6}{it:As many do-files as clusers used.}
*!{dup 78:{c -}}{asis}
real scalar parallel_write_do(
    string scalar inputname,
    string scalar parallelid,
    | real scalar nclusters,
    real   scalar prefix,
    real   scalar matasave,
    real   scalar getmacros,
    string scalar seed,
    string scalar randtype,
    real   scalar nodata,
    string scalar folder,
    string scalar programs,
    real scalar processors
    )
{
    real vector input_fh, output_fh
    string scalar line, fname
    string scalar memset, maxvarset, matsizeset
    real scalar i
    string colvector seeds

    // Checking optargs
    if (matasave == J(1,1,.)) matasave = 0
    if (prefix == J(1,1,.)) prefix = 1
    if (getmacros == J(1,1,.)) getmacros = 0
    if (nclusters == J(1,1,.)) {
        if (strlen(st_global("PLL_CLUSTERS"))) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
        else {
            errprintf("You haven't set the number of clusters\nPlease set it with -{cmd:parallel setclusters} {it:#}-}\n")
            return(198)
        }
    }
    
    /* Check seeds and seeds length */
    if (seed == J(1,1,""))
    {
        seeds = parallel_randomid(5, randtype, 0, nclusters, 1)
        st_local("pllseeds", invtokens(seeds'))
    }
    else
    {
        st_local("pllseeds", seed)
        seeds = tokens(seed)
        /* Checking seeds length */
        if (length(seeds) > nclusters)
        {
            errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
            return(123)
        }
        else if (length(seeds) < nclusters)
        {
            errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
            return(122)
        }
    }
    if (nodata == J(1,1,.)) nodata = 0
    if (folder == J(1,1,"")) folder = c("pwd")

    real scalar progsave
    if (programs !="") progsave = 1
    else progsave = 0
    
    /* Checks for the MP version */
    if (!c("MP") & processors != 0 & processors != J(1,1,.)) display("{result:Warning:}{text: processors option ignored...}")
    else if (processors == J(1,1,.) | processors == 0) processors = 1

    real scalar err
    err = 0
    if (progsave)  err = parallel_export_programs(folder+"__pll"+parallelid+"_prog.do", programs, folder+"__pll"+parallelid+"_prog.log")
    if (getmacros) parallel_export_globals(folder+"__pll"+parallelid+"_glob.do")

    if (err)
    {
        errprintf("An error has occurred while exporting -programs-")
        return(err)
    }
    
    for(i=1;i<=nclusters;i++) 
    {
        // Sets dofile
                fname = folder+"__pll"+parallelid+"_do"+strofreal(i,"%04.0f")+".do"
        if (fileexists(fname)) unlink(fname)
        output_fh = fopen(fname, "w", 1)
        
        // Step 1
        fput(output_fh, "capture {")
        fput(output_fh, "clear")
        if (c("MP")) fput(output_fh, "set processors "+strofreal(processors))
        fput(output_fh, `"cd ""'+folder+`"""')
        
        //Copy over the adopath & matalibs order
        //PERSONAL is the most likely to be overwritten and referenced in S_ADO. (could do others)
        fput(output_fh, `"sysdir set PERSONAL ""' + st_global("c(sysdir_personal)") +`"""')
        fput(output_fh, "global S_ADO = `"+`"""'+st_global("S_ADO")+`"""'+"'")
        fput(output_fh, "mata: mata mlib index")
        fput(output_fh, `"mata: mata set matalibs ""'+st_global("c(matalibs)")+`"""')
            
        fput(output_fh, "set seed "+seeds[i])
        
        if (st_global("PLL_INCLUDE_FILE")!=""){
            fput(output_fh, `"include ""'+st_global("PLL_INCLUDE_FILE")+`"""')
        }

        /* Parallel macros to be used by the current user */
        fput(output_fh, `"noi di "{hline 80}""')
        fput(output_fh, `"noi di "Parallel computing with stata (by GVY)""')
        fput(output_fh, `"noi di "{hline 80}""')
        fput(output_fh, sprintf(`"noi di \`"cmd/dofile   : "%s""'"', inputname))
        fput(output_fh, sprintf(`"noi di "pll_id       : %s""',parallelid))
        fput(output_fh, sprintf(`"noi di "pll_instance : %g/%g""',i,nclusters))
        fput(output_fh,         `"noi di "tmpdir       : \`c(tmpdir)'""')
        fput(output_fh,         `"noi di "date-time    : \`c(current_time)' \`c(current_date)'""')
        fput(output_fh,         `"noi di "seed         : \`c(seed)'""')
        fput(output_fh, `"noi di "{hline 80}""')
        fput(output_fh, "local pll_instance "+strofreal(i))
        fput(output_fh, "local pll_id "+parallelid)
        fput(output_fh, "global pll_instance "+strofreal(i))
        fput(output_fh, "global pll_id "+parallelid)
        
        // Data requirements
        if (!nodata)
        {
            if (c("MP") | c("SE")) 
            {
                // Building data limits
                memset     = sprintf("%9.0f",c("memory")/nclusters)
                maxvarset  = sprintf("%g",c("maxvar"))
                matsizeset = sprintf("%g",c("matsize"))

                // Writing data limits
                if (!c("MP")) fput(output_fh, "set memory "+memset+"b")
                fput(output_fh, "set maxvar "+maxvarset)
                fput(output_fh, "set matsize "+matsizeset)
            }
        }
        /* Checking data setting is just fine */
        fput(output_fh, "}")
        fput(output_fh, "local result = _rc")
        fput(output_fh, "if (c(rc)) {")
        fput(output_fh, `"cd ""'+folder+`"""')
        fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while setting memory")"')
        fput(output_fh, "clear")
        fput(output_fh, "exit")
        fput(output_fh, "}")
        
        // Loading programs
        if (progsave)
        {
            fput(output_fh, sprintf("\n/* Loading Programs */"))
            fput(output_fh, "capture {")
            fput(output_fh, "run "+folder+"__pll"+parallelid+"_prog.do")
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "local result = _rc")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"cd ""'+folder+`"""')
            fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading programs")"')
            fput(output_fh, "clear")
            fput(output_fh, "exit")
            fput(output_fh, "}")
        }
        
        /* Checking for break key 
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()") */
        
        // Mata objects loading
        if (matasave)
        {
            fput(output_fh, sprintf("\n/* Loading Mata Objects */"))
            fput(output_fh, "capture {")
            fput(output_fh, `"mata: mata matuse ""'+folder+"__pll"+parallelid+`"_mata.mmat""')
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "local result = _rc")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"cd ""'+folder+`"""')
            fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading mata objects")"')
            fput(output_fh, "clear")
            fput(output_fh, "exit")
            fput(output_fh, "}")
        }
        
        /* Checking for break key */
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()")
        
        // Globals loading
        if (getmacros)
        {
            fput(output_fh, sprintf("\n/* Loading Globals */"))
            fput(output_fh, "capture {")
            fput(output_fh, `"cap run ""'+folder+"__pll"+parallelid+`"_glob.do""')
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"  cd ""'+folder+`"""')
            fput(output_fh, `"  mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while loading globals")"')
            fput(output_fh, "  clear")
            fput(output_fh, "  exit")
            fput(output_fh, "}")
        }
        
        /* Checking for break key */
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()")
                
        // Step 2        
        fput(output_fh, "capture {")
        fput(output_fh, "  noisily {")
        
        // If it is not a command, i.e. a dofile
        if (!nodata) fput(output_fh, `"    use ""'+folder+"__pll"+parallelid+`"_dataset" if _"'+parallelid+"cut == "+strofreal(i))
        
        /* Checking for break key */
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()")
        
        if (!prefix) {
            input_fh = fopen(inputname, "r", 1)
            
            while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, "    "+line)    
            fclose(input_fh)
        } // if it is a command
        else fput(output_fh, "    "+inputname)
        
        fput(output_fh, "  }")
        fput(output_fh, "}")

        /* Checking programs loading is just fine */
        fput(output_fh, "if (c(rc)) {")
        fput(output_fh, `"  cd ""'+folder+`"""')
        fput(output_fh, `"  mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while running the command/dofile")"')
        fput(output_fh, "  clear")
        fput(output_fh, "  exit")
        fput(output_fh, "}")

        fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+folder+"__pll"+parallelid+"_finito"+strofreal(i,"%04.0f")+`"","while executing the command")"')

        if (!nodata) fput(output_fh, `"save ""'+folder+"__pll"+parallelid+"_dta"+strofreal(i,"%04.0f")+`"", replace"')
        
        // Step 3
        fput(output_fh, `"cd ""'+folder+`"""')
        fclose(output_fh)
    }
    return(0)
}
end

*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_write_do.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
