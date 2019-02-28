*! parallel_estout vers 0.14 10may2014
*! auth George G Vega
//Hidden (undocumented and not called by normal functioning) utility
mata
// mata clear
/*
 * @brief Process e() and store it as a plain-text file
 * @param stmatname Name of e()
 * @param fn File name where to save the file
 * @param fappend whether to append or replace the file
 */
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
	
	randtype=""
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
void parallel_eststore_append(
	string scalar fn,
	| string scalar fns,
	string scalar expr)
{

	real scalar i, nchildren
	string scalar parallelid
	string rowvector files
	
	/* If there are no arguments, ther it should be parallel using it */	
	if (args()==1) 
	{
		/* Retrieving information from parallel */
		parallelid = st_global("r(pll_id)")
		nchildren  = strtoreal(st_global("PLL_CHILDREN"))
		
		files = J(1,nchildren,"")
		for(i=1;i<=nchildren;i++)
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

