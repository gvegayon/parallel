*! vers 0.14.4 16apr2014
*! author: George G. Vega

/**
 * @brief export programs loaded in the current sesion.
 * @param ouname Name of the file that will contain the programs.
 * @param programlist List of programs to be exported.
 * @param inname Name of the tmp file that will be used as log.
 * @return A do-file ready to be runned to load programs.
 */
mata:
void parallel_export_programs(
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
	stata("log using "+inname+", text replace name(plllog"+st_local("parallelid")+")")

	stata("noisily program list "+programlist)
	stata("log close plllog"+st_local("parallelid"))
	stata("set trace "+oldsettrace)
	
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
	string scalar space
	space = "[\s ]*"+sprintf("\t")+"*"
	pathead = "^"+space+"[^0-9][a-zA-Z_]+([a-zA-Z0-9_]*)(,"+space+"[a-zA-Z]*)?[:]"+space+"$"
	patnext = "^[>] "
	
	while ((line = fget(in_fh))!=J(0,0,"")) {
		
		// Enters if it is a start of a program
		if(regexm(line, pathead)) {
			// Writes the header
			fput(ou_fh, sprintf("program def %s", subinstr(line, ":", "")))
			line = fget(in_fh)
		
			// While it is whithin the program
			while (line!=J(0,0,"")) {
				if (regexm(line, patnext)) { // If it is a trimmed version of the program
					fwrite(ou_fh, regexr(line, patnext,""))
				}
				else if (strlen(line) == 0 | !regexm(line, "^"+space+"[0-9]+\.")) { // If it is the last line of the program
					fput(ou_fh, sprintf("\nend"))
					line = fget(in_fh)
					break
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
