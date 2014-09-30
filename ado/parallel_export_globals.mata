*! parallel_export_globals vers 0.14.7.23 23jul2014 @ 22:10:27
*! author: George G. Vega Yon

mata:

/**oxygen
* @brief Writes out global macros and scalrs to the dofile.
* @param  outname Name of the new do-file.
* @param  out_fh If a file is already open, the user can export the globals to it.
* @returns A do-file eady to be runned and define globals.
*/
void parallel_export_globals(|string scalar outname, real scalar ou_fh, 
							string scalar mat_outname) {
	
	real   scalar isnewfile, glob_ind
	string scalar gname, gvalue, FORBIDDEN, line
	string colvector global_names
	pointer scalar mat_p

	if (outname == J(1,1,"")) outname = parallel_randomid(10,"",1,1,1)+".do"
	
	if (ou_fh == J(1,1,.)) {
		if (fileexists(outname)) unlink(outname)
		ou_fh = fopen(outname, "w", 1)
		isnewfile = 1
	}
	else isnewfile = 0

	FORBIDDEN = "^(S\_FNDATE|S\_FN|F[0-9]|S\_level|S\_ADO|S\_FLAVOR|S\_OS|S\_MACH|!)"

	// Global macros
	global_names = st_dir("global", "macro", "*")
	for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
		gname = global_names[glob_ind,1]
		if (regexm(gname, FORBIDDEN) | !regexm(gname, "^[a-zA-Z]")) continue
		
		gvalue = st_global(gname)
		line = "global "+gname+" "+gvalue
		fput(ou_fh, line)
	}
	
	// Numerical Scalars
	global_names = st_dir("global", "numscalar", "*")
	for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
		gname = global_names[glob_ind,1]
		if (regexm(gname, FORBIDDEN) | !regexm(gname, "^[a-zA-Z]")) continue
		
		gvalue = strofreal(st_numscalar(gname))
		line = "scalar "+gname+" = "+gvalue
		fput(ou_fh, line)
	}
	
	// String Scalars
	global_names = st_dir("global", "strscalar", "*")
	for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
		gname = global_names[glob_ind,1]
		if (regexm(gname, FORBIDDEN) | !regexm(gname, "^[a-zA-Z]")) continue
		
		gvalue = st_strscalar(gname)
		line = "scalar "+gname+`" = ""'+gvalue+`"""'
		fput(ou_fh, line)
	}
	
	if (isnewfile) fclose(ou_fh)
	
	// Matrices
	
	if (mat_outname == J(1,1,"")) mat_outname = "mat"+parallel_randomid(10,"",1,1,1)+".mmat"
	
	global_names = st_dir("global", "matrix", "*")
	for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
		gname = global_names[glob_ind,1]
		if (regexm(gname, FORBIDDEN) | !regexm(gname, "^[a-zA-Z]")) continue
		
		mat_p = crexternal("pll_mt_val_"+gname)
		(*mat_p) = st_matrix(gname)
		mat_p = crexternal("pll_mt_rstripe_"+gname)
		(*mat_p) = st_matrixrowstripe(gname)
		mat_p = crexternal("pll_mt_cstripe_"+gname)
		(*mat_p) = st_matrixcolstripe(gname)
	}
	stata("qui mata: mata matsave "+mat_outname+" pll_mt_*, replace")
	//Cleanup global namespace
	for(glob_ind=1; glob_ind<=rows(global_names); glob_ind++) {
		gname = global_names[glob_ind,1]
		if (regexm(gname, FORBIDDEN) | !regexm(gname, "^[a-zA-Z]")) continue
		
		rmexternal("pll_mt_val_"+gname)
		rmexternal("pll_mt_rstripe_"+gname)
		rmexternal("pll_mt_cstripe_"+gname)
	}
	
}
end

