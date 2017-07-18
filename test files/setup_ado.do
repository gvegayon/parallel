//This automates setting up the adopath for the working copy. 
//(Complicated because Windows has platform-specific files)
platformname
global S_ADO="../ado/;../ado/`r(platformname)';UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"
mata: mata mlib index

//When debugging
//  Notes compilation point of error in {}s (not exactly line number but can be helpful)
//  See also matalnum setting in compile.do
//set matadebug on
