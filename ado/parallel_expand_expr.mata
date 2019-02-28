*! vers 0.14.4 9apr2014
*! auth George G. Vega

/**
 * @brief Expands a fmt string combining numlists
 * @author George G. Vega
 * @param expr An expression containing a fmt and numlists
 * @param pchar (optional) Parsing char which separates -fmt- and numlists
 * @param sep
 * @returns
 */

mata:
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

