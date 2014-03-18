*! vers 0.14.3 18mar2014
/**oxygen 
 * @brief Set of tools to prevent parallel instances to overlap.
 * @param action Action to be taken.
 * @param pll_id Parallel process id.
 * @param result Pointer to list of files that can be removed (without stopping
                 another parallel process).
 * @returns Depends on the action.
 */
mata:
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
