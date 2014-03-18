*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon

/**oxygen 
 * @brief Mata's Random id generation.
 * @param n Number of random ids to generate.
 * @param randtype Type of random algorithm to use.
 * @param alpha Whether to use or not alphanum.
 * @param nele Length of each random id generated.
 * @param silent Whether to run quietly or not.
 * @returns String colvector of random ids.
 */
mata:
string colvector parallel_randomid(|real scalar n, string scalar randtype, real scalar alpha, real scalar nele, real scalar silent) {
	
	string scalar curseed
	string scalar newseed, tmpid
	string scalar line
	string vector id, id2
	real scalar rn_fh, i, j
	
	id = J(0,1,"")
	
	if (alpha == J(1,1,"")) alpha = 1
	if (nele == J(1,1,.)) nele = 1
	if (silent == J(1,1,.)) silent = 0
	
	// Checking if randtype is supported
	if (!regexm(randtype,"^(random.org|datetime)$") & strlen(randtype) > 0) {
		errprintf("randtype -%s- not supported\nPlease try with -random.org- or -datetime-\n", randtype)
		exit(198)
	}
	
	// Parsing id length
	if (n==J(1,1,.)) n = 10
	
	// Keeping the current seed value (if its going to change)
	if (randtype!=J(1,1,"")) curseed = c("seed")
	
	if (randtype=="random.org") {
		if (!silent) printf("Connecting to random.org API...")
		if (alpha) { /* Gets strings */
			rn_fh = _fopen("http://www.random.org/strings/?num="+strofreal(nele)+"&len="+strofreal(n)+"&digits=on&upperalpha=off&loweralpha=on&unique=on&format=plain&rnd=new","r")
		}
		else {       /* Gets integers */
			rn_fh = _fopen("http://www.random.org/integers/?num="+strofreal(nele)+"&min="+ strofreal(10^(n))+"&max="+strofreal(10^(n+1)-1)+"&col=1&base=10&format=plain&rnd=new", "r")
		}
		
		if (rn_fh >= 0) { // If the connection works fine
			id = J(0,1,"")
			while ((line=fget(rn_fh)) != J(0,0,"") ) {
				id = id\ line
			}
			fclose(rn_fh)
			if (!silent) printf("success!\n")
			
			// Returns the random id from random.org
			for(i=1;i<=nele;i++) {
				if (!silent) display(sprintf("Your random id is {ul:%s} (saved in {stata return list:r(id"+strofreal(i)+")})\n", id[i]))
				st_global("r(id"+strofreal(i)+")", id[i])
			}
			return(id)
			
		}
		else { // If the connection does not work
			errprintf("Can not connect to -random.org-\n")
			exit(rn_fh)
		}
	}
	else if (randtype=="datetime") {
		newseed = strtrim(sprintf("%15.0f",
			sum(ascii(c("current_date")))+strtoreal(subinstr(c("current_time"),":",""))))
		stata("set seed "+newseed)
	}
	
	if (alpha) id2 = (tokens(c("alpha")), strofreal(1..9),tokens(c("alpha")), strofreal(1..9)	)
	else id2 = strofreal(1..9),strofreal(1..9),strofreal(1..9),strofreal(1..9)

	for(j=1;j<=nele;j++) {
		id2 = jumble(id2')'
		tmpid = ""		
		for(i=1;i<=n;i++) {
			tmpid = tmpid+id2[i]
		}
		id = id\tmpid
	}
	
	if (randtype!=J(1,1,"")) stata("set seed "+curseed)
	
	// Returns the random id
	for(i=1;i<=nele;i++) {
		if (!silent) display(sprintf("Your random id is {ul:%s} (saved in {stata return list:r(id"+strofreal(i)+")})\n", id[i]))
		st_global("r(id"+strofreal(i)+")", id[i])
	}
	
	return(id)
}
end

