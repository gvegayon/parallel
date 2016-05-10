args filename
file open fhandle using "`filename'", write text replace
platformname
file write fhandle "`r(platformname)'"
file close fhandle
