local pll_instance 1
local pll_id 1asd156

clear all
mata mata clear

mata
/*
void function parallel_save_estimates(
	string scalar return_list,
	| real scalar append
	)
{

	real scalar i, fh
	string scalar fn
	string rowvector

}
*/

// List the names of ereturn list output
pointer(string scalar) colvector function parallel_xreturn_list(
	| string scalar cmd,
	string scalar returntype,
	string scalar randtype)
{
	real scalar fh, curps
	string scalar fn, txt, re
	pointer(string scalar) colvector rlist
		
	fn = "pll_return_list_"+parallel_randomid(10,randtype,1,1,1)+".log"
	
	if (returntype == J(1,1,"")) returntype = "e"
	
	// Creating return list
	stata("cap log close "+fn)
	stata("log using "+fn+", replace")
	if (cmd != J(1,1,"")) stata(cmd)
	stata(returntype+"return list")
	stata("log close")
	
	fh = fopen(fn, "r")
	
	rlist = J(20,1,NULL)
	rlist[1] = &""
	curps = 1
	re = "^[ ]*("+returntype+"[(][a-zA-Z0-9_]+[)])"
	while((txt = fget(fh)) != J(0,0,""))
	{
		// If we are at the start of the macros list
		if (regexm(txt,"^([a-zA-Z]+)[:]"))
		{
			rlist[1] = &(*rlist[1] + " "+regexs(1))
			rlist[++curps] = &""
			continue
		}
		
		if (regexm(txt, re)) rlist[curps] = &(*rlist[curps] + " " + regexs(1))
	}
	
	fclose(fh)
	unlink(fn)
	
	return(rlist[1::curps])
}

// Process a matrix and store it
void function parallel_process_mat(
	string scalar stmatname,
	| string scalar fn,
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
	
	if (fappend == J(1,1,.)) fappend = 1
	
	// Matrix parsing
	stmat       = st_matrix(stmatname)
	stcolnames0 = st_matrixcolstripe(stmatname)
	strownames0 = st_matrixrowstripe(stmatname)
	
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
	if (fn == J(1,1,"")) fn = st_local("pll_id")+"mat"+st_local("pll_instance")+".tab"
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
			txt = txt + tabheader[i] + (i == nhead ? "" : sprintf("\t"))
		fput(fh, txt)
		
		// Writing the file lines
		for(i=1;i<=nrow;i++)
		{
			txt = ""
			for(j=1;j<=ncol;j++)
				txt = txt + sprintf("%g",stmat[i,j]) + (j==ncol? "" : sprintf("\t"))
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
			fh0   = fopen((fn0=parallel_randomid(10,randtype,1,1,1)), "w")
			
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
		stmattmp
		for(i=1;i<=nrow;i++)
		{
			txt = ""
			for(j=1;j<=ncol;j++)
				txt = txt+sprintf("%g",stmattmp[i,j]) + sprintf((j==ncol? "" : "\t"))
				
			fput(fh, txt)
		}
		
		fclose(fh)
		
		return
	}
	
	
	
}

end

sysuse auto
summ

mata 
rlist = parallel_xreturn_list("regress mpg weight c.weight#c.weight foreign")
rlist

for(i=1;i<=length(rlist);i++) *rlist[i]

end
mata nf = "5"
mata unlink("nuevo"+nf+".tab")
mata parallel_process_mat("e(b)","",0)
sample 90
regress mpg weight c.weight#c.weight foreign

mata  parallel_process_mat("e(b)")

regress mpg c.weight#c.weight foreign

mata  parallel_process_mat("e(b)")

regress mpg c.weight#c.weight foreign rep78

mata  parallel_process_mat("e(b)")

regress mpg foreign rep78 c.weight#c.weight

mata  parallel_process_mat("e(b)")
local pll_instance 1
local pll_id 1asd156
