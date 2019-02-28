*! version 0.13.10.2  2oct2013
*! author: George G. Vega Yon

/**oxygen
* @brief Stops the child process if the mother instance has requiered so.
* @param parallelid Parallel process id. 
* @param pllinstance Parallel instance id.
* @returns Stops the child process.
*/

mata:
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

/**oxygen
* @brief Stops the child process if the mother instance has requiered so.
* @param parallelid Parallel id. 
* @param pllinstance Parallel instance
* @returns Returns -1- if the mother process has stop, else returns -0-.
*/
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

