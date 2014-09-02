*! parallel_export_globals vers 0.14.7.23 23jul2014 @ 22:10:27
*! author: George G. Vega Yon

mata:

/**oxygen
* @brief Looks for global macros and writes to the dofile.
* @param  outname Name of the new do-file.
* @param  out_fh If a file is already open, the user can export the globals to it.
* @returns A do-file eady to be runned and define globals.
*/
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

