*! version 0.13.09.30  30sep2013
*! author: George G. Vega Yon

/**oxygen 
 * @brief Writes a diagnosis to be read by -parallel_finito()-
 * @param diagnosis Text to be written.
 * @param fname File where to write the diagnosis.
 * @param msg Message to include at the end of the file.
 * @returns A file with one or two lines.
 */
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
