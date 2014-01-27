*! vers 0.13.10.7 7oct2013
mata:
void program_export(
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
	stata("cap log close "+inname)
	stata("log using "+inname+".txt, text replace name(log"+inname+")")
	stata("noisily program list "+programlist)
	stata("log close log"+inname)
	stata("set trace "+oldsettrace)
	
	inname = inname+".txt"
	
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
	pathead = "^[^0-9][a-zA-Z_]+(, [a-zA-Z]*)?[:][\s ]*$"
	patnext = "^[>][\s ]"
	
	while ((line = fget(in_fh))!=J(0,0,"")) {
		// Enters if it is a start of a program
		if(regexm(line, pathead)) {
		
			// Writes the header
			fput(ou_fh, sprintf("program def %s", subinstr(line, ":", "")))
			line = fget(in_fh)
		
			// While it is whithin the program
			while (line!=J(0,0,"")) {
				if (strlen(line) == 0| !regexm(line, "^[\s ]*[0-9]+\.")) { // If it is the last line of the program
					fput(ou_fh, sprintf("\nend"))
					line = fget(in_fh)
					break
				}
				else if (regexm(line, patnext)) { // If it is a trimmed version of the program
					fwrite(ou_fh, regexr(line, patnext,""))
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
