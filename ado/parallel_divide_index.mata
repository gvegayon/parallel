mata:

/* Compare observations i and j */
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
