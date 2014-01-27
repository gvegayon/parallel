*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -globals_export.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
////////////////////////////////////////////////////////////////////////////////
// Looks for global macros and writes to the dofile
mata:
*! {smcl}
*! {marker globals_export}{bf:function -{it:globals_export}- in file -{it:globals_export.mata}-}{asis}
void globals_export(|string scalar outname , real scalar ou_fh)
    {
    
    real   scalar ismacro, forbidden, in_fh, isnewfile
    string scalar line, macname, macvalu, typeofmacro, REGEX, FORBIDDEN
    string scalar logname

    if (outname == J(1,1,"")) outname = parallel_randomid(10,"",1,1,1)
    
    if (ou_fh == J(1,1,.)) {
        ou_fh = fopen(outname, "w", 1)
        isnewfile = 1
    }
    else isnewfile = 0
    
    // Writing log
    logname = parallel_randomid(10,"",1,1,1)
    
    stata("cap log close log"+logname)
    stata("log using "+logname+".log, text replace name(log"+logname+")")
    stata("noisily macro dir")
    stata("log close log"+logname)
    
    in_fh = fopen(logname+".log", "r", 1)
    
    // Step 1
    REGEX = "^([0-9a-zA-Z_]+)([:][ ]*)(.*)"
    FORBIDDEN = "^(S[_]FNDATE|S[_]FN|F[0-9]|S[_]level|S[_]ADO|S[_]FLAVOR|S[_]OS|S[_]MACH)([ ]*.*$)"
    
    line = fget(in_fh)
    while (line!=J(0,0,""))
    {
        // Check wheater it is a macro or not (and not system macros)
        forbidden = regexm(line, FORBIDDEN)
        ismacro = regexm(line, REGEX)
        
        if (ismacro & !forbidden)
        {
            macname = regexs(1)
            
            // Checks wheather if it is a local or global macro
            if (!regexm(macname, "^[_]"))
            {
                macvalu = st_macroexpand("$"+macname)
                typeofmacro = "global "
                line = typeofmacro+macname+" "+macvalu
                fput(ou_fh, line)
            }
        }
        line = fget(in_fh)
    }
    
    fclose(in_fh)
    unlink(logname+".log")
    if (isnewfile) fclose(ou_fh)
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -globals_export.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -normalizepath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
mata:
*! {smcl}
*! {marker normalizepath}{bf:function -{it:normalizepath}- in file -{it:normalizepath.mata}-}{asis}
transmorphic normalizepath(
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
*! {c |} {bf:End of file -normalizepath.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_break.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.13.10.2  2oct2013
*! Aborts execution and returns to the current instancee
mata:
*! {smcl}
*! {marker parallel_break}{bf:function -{it:parallel_break}- in file -{it:parallel_break.mata}-}{asis}
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

*! {smcl}
*! {marker _parallel_break}{bf:function -{it:_parallel_break}- in file -{it:parallel_break.mata}-}{asis}
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
mata:
*! {smcl}
*! {marker parallel_clean}{bf:function -{it:parallel_clean}- in file -{it:parallel_clean.mata}-}{asis}
void parallel_clean(|string scalar parallelid, real scalar cleanall, real scalar force) {
    
    real scalar i ;
    string colvector files, sbfiles;
    
    // Checking arguments
    if (parallelid == J(1,1,"")) parallelid = st_global("r(pll_id)");
    if (cleanall == J(1,1,.)) cleanall = 0;
    if (force==J(1,1,.)) force = 0;
    
    if (!cleanall & strlen(parallelid)) // If its not all
    { 
        files = dir("","files","__pll"+parallelid+"_*") \ dir("","files","l__pll"+parallelid+"_*")
    }
    else if (cleanall)
    {           // If its all
        files = dir("","files","__pll*") \ dir("","files","l__pll*")
    }
    
    /* Extracting files that are in use */
    if (!force) parallel_sandbox(1,"",&sbfiles)
            
    /* Checking if there is anything to clean */
    if (files == J(0,1,"")) display(sprintf("{text:parallel clean:} {result: nothing to clean...}"))
    else {
        /* Checking sandbox files */
        for(i=1;i<=length(sbfiles);i++)
            files = select(files, files:!=sbfiles[i])
    
        /* Looping over file names */
        for(i=1;i<=rows(files);i++)
            unlink(files[i])
    }
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
mata:

/* Compare observations i and j */
*! {smcl}
*! {marker parallel_compare_matrix}{bf:function -{it:parallel_compare_matrix}- in file -{it:parallel_divide_index.mata}-}{asis}
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

/* Generate index for dividing a dataset */
*! {smcl}
*! {marker parallel_divide_index}{bf:function -{it:parallel_divide_index}- in file -{it:parallel_divide_index.mata}-}{asis}
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
*! {c |} {bf:Beginning of file -parallel_finito.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.13.10.3  3oct2013
* Waits until every process finishes or stops the processes
mata:
*! {smcl}
*! {marker parallel_finito}{bf:function -{it:parallel_finito}- in file -{it:parallel_finito.mata}-}{asis}
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
    real scalar suberrors, i, errornum
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
        fname = sprintf("__pll%s_do%g.log", parallelid, i)
        time = 0
        while (!fileexists(fname) & ((++time)*100 < timeout) & !breakkey())
            stata("sleep 100")
            
        if (!fileexists(fname)) 
        {
            display(sprintf("{it:cluster %g} {error:has finished with a connection error -601- (timeout) ({stata search r(601):see more})...}", i))
            suberrors++
            continue
        }
        else pendingcl = pendingcl, i
            
        timeout = timeout - time*100
    }
    
    /* If there are as many errors as clusters, then exit */
    if (suberrors == nclusters) return(suberrors)
    
    while(length(pendingcl)>0)
    {
        
        // Building filename
        for (i=1;i<=nclusters;i++)
        {
            /* If this cluster is ready, then continue */
            if (!any(pendingcl :== i)) continue
            
            fname = sprintf("__pll%s_finito%g", parallelid, i)
            
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
                fname = sprintf("__pll%s_finito%g", parallelid, i)
                
            }
        
            if (fileexists(fname)) // If the file exists
            { 
                /* Opening the file and looking for somethign different of 0
                (which is clear) */
                in_fh = fopen(fname, "r", 1)
                if ((errornum=strtoreal(fget(in_fh))))
                {
                    msg = fget(in_fh)
                    if (msg == J(0,0,"")) display(sprintf("{it:cluster %g} {error:has finished with an error -%g- ({stata search r(%g):see more})...}", i, errornum, errornum))
                    else display(sprintf("{it:cluster %g} {error:has finished with an error -%g- %s ({stata search r(%g):see more})...}", i, errornum, msg, errornum))
                    suberrors++
                }
                else display(sprintf("{it:cluster %g} {text:has finished without any error...}", i))
                fclose(in_fh)
                
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
*! {smcl}
*! {marker parallel_for}{bf:function -{it:parallel_for}- in file -{it:parallel_for.mata}-}{asis}
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
*! {c |} {bf:Beginning of file -parallel_randomid.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
// Mata's Random id generation
mata:
*! {smcl}
*! {marker parallel_randomid}{bf:function -{it:parallel_randomid}- in file -{it:parallel_randomid.mata}-}{asis}
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
    if (!regexm(randtype,"^(random.org|datetime)$") & strlen(randtype) > 0) {
        errprintf("randtype -%s- not supported\nPlease try with -random.org- or -datetime-\n", randtype)
        exit(198)
    }
    
    // Parsing id length
    if (n==J(1,1,.)) n = 10
    
    // Keeping the current seed value (if its going to change)
    if (randtype!=J(1,1,"")) curseed = c("seed")
    
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
                id = id\ line
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
            sum(ascii(c("current_date")))+strtoreal(subinstr(c("current_time"),":",""))))
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
        id = id\tmpid
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
*! {c |} {bf:Beginning of file -parallel_run.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
////////////////////////////////////////////////////////////////////////////////
// Runs Stata in batch mode
mata:
*! {smcl}
*! {marker parallel_run}{bf:function -{it:parallel_run}- in file -{it:parallel_run.mata}-}{asis}
real scalar parallel_run(
    string scalar parallelid, 
    |real scalar nclusters, 
    string scalar paralleldir,
    real scalar timeout
    ) {

    real scalar fh, i
    
    // Setting default parameters
    if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
    if (paralleldir == J(1,1,"")) paralleldir = st_global("PLL_DIR")
    
    // Message
    display("{text:Parallel Computing with Stata} {result:(by GVY)}")
    display("{text:Clusters:} {result:"+strofreal(nclusters)+"}")
    display("{text:ID:} {result:"+parallelid+"}")
    
    if (strlen(st_local("randtype"))) display("{text:{it:Note: randtype = "+st_local("randtype")+"}}")

    if (c("os") != "Windows") { // MACOS/UNIX
        unlink("__pll"+parallelid+"_shell.sh")
        fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)
        fput(fh, "echo Stata instances PID:")
        
        // Writing file
        if (c("os") != "Unix") {
            for(i=1;i<=nclusters;i++) {
                fput(fh, paralleldir+" -e do __pll"+parallelid+"_do"+strofreal(i)+".do &")
            }
        }
        else {
            for(i=1;i<=nclusters;i++) {
                fput(fh, paralleldir+" -b do __pll"+parallelid+"_do"+strofreal(i)+".do &")
            }
        }
        
        fclose(fh)
        
        // stata("shell sh __pll"+parallelid+"shell.sh&")
        stata("winexec sh __pll"+parallelid+"_shell.sh")
    }
    else { // WINDOWS
        for(i=1;i<=nclusters;i++) {
            // Lunching procces
            stata("winexec "+paralleldir+" /e /q do __pll"+parallelid+"_do"+strofreal(i)+".do ")
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
*! vers 0.13.10.7 7oct2013
mata:
*! {smcl}
*! {marker parallel_sandbox}{bf:function -{it:parallel_sandbox}- in file -{it:parallel_sandbox.mata}-}{asis}
void parallel_sandbox(
    real scalar action,   /* 
        0: Check and create, if error aborts with error ;
        1: Returns a list of files that can be erased 
        2: Delets the respective sandbox file 
        3: Updates the status of a sandbox file
        */
    |string scalar pll_id,
    pointer(scalar) scalar result
    )
{
    /* Definign variables */
    real scalar fh,i;
    string colvector sbids, sbfnames;
    
    /* Checks if a parallel instance is currently running with the same pll id name */
    if (action==0)
    {
        /* Checking if the files exist */
        if (fileexists("__pll"+pll_id+"_sandbox"))
            _error(912,sprintf("-%s- aldready in use. Please change the seed.", pll_id))
        
        /* Creating the new file */
        fh = fopen("__pll"+pll_id+"_sandbox", "w");
        fput(fh,"pll_id:"+pll_id);
        fput(fh,"date:"+c("current_date")+" "+c("current_time"))
        fclose(fh);
        
        return
    }
    
    /* Returns a list of files which are not intended to be erased */
    if (action==1)
    {
        /* Listing the files that shuldn't be removed */
        sbids = dir(".","files","__pll*sandbox");
        
        sbfnames = J(0,1,"");
        
        if (length(sbids))
        {
            sbids = regexr(regexr(sbids, "l?__pll", ""), "_.*", "");
        
            for(i=1;i<=length(sbids);i++)
                sbfnames = sbfnames\dir(".","files","__pll"+sbids[i]+"*");
        }

        /* Assigning the value */
        (*result) = sbfnames
        
        return
    }
    
    /* Removes the corresponding file to be removed */
    if (action==2)
    {
        unlink("__pll"+pll_id+"_sandbox")
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
mata:
*! {smcl}
*! {marker parallel_setclusters}{bf:function -{it:parallel_setclusters}- in file -{it:parallel_setclusters.mata}-}{asis}
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
*! {c |} {bf:Beginning of file -parallel_setstatadir.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
mata:
*! {smcl}
*! {marker parallel_setstatadir}{bf:function -{it:parallel_setstatadir}- in file -{it:parallel_setstatadir.mata}-}{asis}
real scalar parallel_setstatadir(string scalar statadir, | real scalar force) {

    string scalar bit, flv

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
            if (c("stata_version") < 11) statadir = c("sysdir_stata")+"w"+flv+"Stata.exe"
            else statadir = c("sysdir_stata")+"Stata"+flv+bit+".exe"
        
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

    // Setting PLL_DIR
    if (force == J(1,1,.) | force == 1)    {
        if (!fileexists(statadir)) return(601)
    }
    
    if (!regexm(statadir, `"^["]"')) st_global("PLL_DIR", `"""'+statadir+`"""')
    else st_global("PLL_DIR", statadir)
    
    display(sprintf("{text:Stata dir:} {result: %s}" ,statadir))
    return(0)
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_setstatadir.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -parallel_write_diagnosis.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! version 0.13.09.30  30sep2013
* Writes a diagnosis to be read by -parallel_finito()-
mata:
*! {smcl}
*! {marker parallel_write_diagnosis}{bf:function -{it:parallel_write_diagnosis}- in file -{it:parallel_write_diagnosis.mata}-}{asis}
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
*! version 0.13.10.7  7oct2013
* Generates the corresponding dofiles
mata:
*! {smcl}
*! {marker parallel_write_do}{bf:function -{it:parallel_write_do}- in file -{it:parallel_write_do.mata}-}{asis}
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
    real scalar progsave,
    real scalar processors
    )
{
    real vector input_fh, output_fh
    string scalar line
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
    if (seed == J(1,0,"") | seed == "")
    {
        seeds = parallel_randomid(5, randtype, 0, nclusters, 1)
    }
    else
    {
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
    if (progsave == J(1,1,.)) progsave = 0
    
    /* Checks for the MP version */
    if (!c("MP") & processors != 0 & processors != J(1,1,.)) display("{it:{result:Warning:} processors option ignored...}")
    else if (processors == J(1,1,.) | processors == 0) processors = 1
    
    if (progsave) program_export("__pll"+parallelid+"_prog.do")
    if (getmacros) globals_export("__pll"+parallelid+"_glob.do")
    
    for(i=1;i<=nclusters;i++) 
    {
        // Sets dofile
        if (fileexists("__pll"+parallelid+"_do"+strofreal(i)+".do")) unlink("__pll"+parallelid+"do"+strofreal(i)+".do")
        output_fh = fopen("__pll"+parallelid+"_do"+strofreal(i)+".do", "w", 1)
        
        // Step 1
        fput(output_fh, "capture {")
        fput(output_fh, "clear")
        if (c("MP")) fput(output_fh, "set processors "+strofreal(processors))
        fput(output_fh, `"cd ""'+folder+`"""')
            
        fput(output_fh, "set seed "+seeds[i])

        /* Parallel macros to be used by the current user */
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
        fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"_finito"+strofreal(i)+`"","while setting memory")"')
        fput(output_fh, "clear")
        fput(output_fh, "exit")
        fput(output_fh, "}")
        
        // Loading programs
        if (progsave)
        {
            fput(output_fh, sprintf("\n/* Loading Programs */"))
            fput(output_fh, "capture {")
            fput(output_fh, "run __pll"+parallelid+"_prog.do")
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "local result = _rc")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"cd ""'+folder+`"""')
            fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"_finito"+strofreal(i)+`"","while loading programs")"')
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
            fput(output_fh, "mata: mata matuse __pll"+parallelid+"_mata.mmat")
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "local result = _rc")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"cd ""'+folder+`"""')
            fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"_finito"+strofreal(i)+`"","while loading mata objects")"')
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
            fput(output_fh, "cap run __pll"+parallelid+"_glob.do")
            /* Checking programs loading is just fine */
            fput(output_fh, "}")
            fput(output_fh, "if (c(rc)) {")
            fput(output_fh, `"cd ""'+folder+`"""')
            fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"_finito"+strofreal(i)+`"","while loading globals")"')
            fput(output_fh, "clear")
            fput(output_fh, "exit")
            fput(output_fh, "}")
        }
        
        /* Checking for break key */
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()")
                
        // Step 2        
        fput(output_fh, "capture {")
        fput(output_fh, "noisily {")
        
        // If it is not a command, i.e. a dofile
        if (!nodata) fput(output_fh, "use __pll"+parallelid+"_dataset if _"+parallelid+"cut == "+strofreal(i))
        
        /* Checking for break key */
        fput(output_fh, sprintf("\n/* Checking for break */"))
        fput(output_fh, "mata: parallel_break()")
        
        if (!prefix) {
            input_fh = fopen(inputname, "r", 1)
            
            while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, line)    
            fclose(input_fh)
        } // if it is a command
        else fput(output_fh, inputname)
        
        fput(output_fh, "}")
        fput(output_fh, "}")
        if (!nodata) fput(output_fh, "save __pll"+parallelid+"_dta"+strofreal(i)+", replace")
        
        // Step 3
        fput(output_fh, `"cd ""'+folder+`"""')
        fput(output_fh, `"mata: parallel_write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"_finito"+strofreal(i)+`"","while running the command/dofile")"')
        fclose(output_fh)
    }
    return(0)
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -parallel_write_do.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:Beginning of file -program_export.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
*! vers 0.13.10.7 7oct2013
mata:
*! {smcl}
*! {marker program_export}{bf:function -{it:program_export}- in file -{it:program_export.mata}-}{asis}
void program_export(
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
    stata("cap log close "+inname)
    stata("log using "+inname+".txt, text replace name(log"+inname+")")
    stata("noisily program list "+programlist)
    stata("log close log"+inname)
    stata("set trace "+oldsettrace)
    
    inname = inname+".txt"
    
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
    pathead = "^[^0-9][a-zA-Z_]+(, [a-zA-Z]*)?[:][\s ]*$"
    patnext = "^[>][\s ]"
    
    while ((line = fget(in_fh))!=J(0,0,"")) {
        // Enters if it is a start of a program
        if(regexm(line, pathead)) {
        
            // Writes the header
            fput(ou_fh, sprintf("program def %s", subinstr(line, ":", "")))
            line = fget(in_fh)
        
            // While it is whithin the program
            while (line!=J(0,0,"")) {
                if (strlen(line) == 0| !regexm(line, "^[\s ]*[0-9]+\.")) { // If it is the last line of the program
                    fput(ou_fh, sprintf("\nend"))
                    line = fget(in_fh)
                    break
                }
                else if (regexm(line, patnext)) { // If it is a trimmed version of the program
                    fwrite(ou_fh, regexr(line, patnext,""))
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
    fwrite(ou_fh,sprintf("\n"))
    fclose(ou_fh)
    return
}
end
*! {smcl}
*! {c TLC}{dup 78:{c -}}{c TRC}
*! {c |} {bf:End of file -program_export.mata-}{col 83}{c |}
*! {c BLC}{dup 78:{c -}}{c BRC}
