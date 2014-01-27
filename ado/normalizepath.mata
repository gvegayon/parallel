mata:
transmorphic normalizepath(
	string scalar path,
	| real scalar exportaslocal
	)
	{
	
	string scalar filename, fileext, fullpath, filedir, curpath
	string rowvector parts
	real scalar i, isfile
	
	if (exportaslocal == J(1,1,.)) exportaslocal = 0
		
	// Replacing folder sep
	fullpath = subinstr(path, "\", "/")
	fullpath = subinstr(path, `"""', "")
	
	// Verifying if there is anything
	if (fileexists(fullpath)) isfile = 1
	else if (direxists(fullpath)) isfile = 0
	else _error(601)
	
	curpath = regexr(pwd(), "/$", "")
	
	if (isfile) {
		if(fileexists(pwd()+fullpath))
			fullpath = subinstr(pwd(),"\","/")+fullpath
	}
	else {
		if(direxists(pwd()+fullpath))
			fullpath = subinstr(pwd(),"\","/")+fullpath
	}
	
	// Cleaning ".." and spliting (parsing)
	parts = tokens(fullpath,"/")
	if (cols(parts) >= 3) {
		for(i=3;i<=cols(parts);i++) {
			if (parts[i] == "..") parts[(i-2)..i] = J(1,3,"")
		}
	}
	
	// Merging all
	fullpath = ""
	for(i=1;i<=cols(parts);i++) fullpath = fullpath+parts[i]
	
	// Replacing "//"
	while (strlen(fullpath) != strlen(regexr(fullpath, "//", "/")))
		fullpath = regexr(fullpath, "//", "/")
	
	// Last check
	if (isfile) {
		if(!fileexists(fullpath)) _error(1)
	}
	else {
		if(!direxists(fullpath)) _error(1)
	}
	
	// Extracting details
	pathsplit(fullpath, filedir, filename)
	fileext = pathsuffix(filename)	
	
	if (exportaslocal) {
		st_local("filedir",filedir)
		st_local("filename",filename)
		st_local("fullpath",fullpath)
		st_local("fileext",fileext)
	}
	else  return((path\fullpath\fileext\filename))
	
}
end
