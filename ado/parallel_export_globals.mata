*! parallel_export_globals vers 0.14.3
*! author: George G. Vega Yon

mata:

/**oxygen
* @brief Looks for global macros and writes to the dofile.
* @param  outname Name of the new do-file.
* @param  out_fh If a file is already open, the user can export the globals to it.
* @returns A do-file eady to be runned and define globals.
*/
void parallel_export_globals(|string scalar outname, real scalar ou_fh) {
	
	real   scalar forbidden, isnewfile
	string scalar logname, macname, macvalu, typeofmacro, FORBIDDEN

	if (outname == J(1,1,"")) outname = parallel_randomid(10,"",1,1,1)
	
	if (ou_fh == J(1,1,.)) {
		if (fileexists(outname)) unlink(outname)
		ou_fh = fopen(outname, "w", 1)
		isnewfile = 1
	}
	else isnewfile = 0
	
	// Writing log
	logname = parallel_randomid(10,"",1,1,1)

	// Step 1
	FORBIDDEN = "^(S[_]FNDATE|S[_]FN|F[0-9]|S[_]level|S[_]ADO|S[_]FLAVOR|S[_]OS|S[_]MACH)([ ]*.*$)"
/* local x : all globals 	
this should work in a cleaner way
*/
	stata("local "+logname+" : all globals")

	string rowvector globals
	real scalar i
	globals = st_local(logname)	

	if (length(globals))
	{
		for(i=1;i<=length(globals);i++)
		{
			macname = globals[i]
			// Check wheater it is a macro or not (and not system macros)
			if (!regexm(macname, FORBIDDEN))
			{		
				macvalu = st_macroexpand("$"+macname)
				typeofmacro = "global "
				macname = typeofmacro+macname+" "+macvalu
				fput(ou_fh, macname)

			}
		}
	}
	
	if (isnewfile) fclose(ou_fh)
}
end
