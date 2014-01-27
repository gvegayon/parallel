*! version 0.13.09.30  30sep2013
* Writes a diagnosis to be read by -parallel_finito()-
mata:
void parallel_write_diagnosis(
	string scalar diagnosis,
	string scalar fname,
	| string scalar msg
) 
{
	real scalar fh
	if (fileexists(fname)) unlink(fname)
	fh = fopen(fname, "w")
	fput(fh, diagnosis)
	fput(fh, msg)
	fclose(fh)
	
}
end
