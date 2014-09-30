mata

// Resampling algorithm
real colvector function parallel_resample(
        | real scalar size,
        real colvector weights
        )
{
        real colvector permut, index, newsample
        real scalar N0, N1, n, i, k, j

        N0 = c("N")

        // Getting the sample size
        if (size < 1) n = max( (1,round(size*N0)) )
        else {
		if (N0 < size)
		{
			printf("N is smaller than the requiered size\n")
			n = N0
		}
		else n = size
	}

        // Expanding the observations index (or not!)
	k = 0
        if (weights != J(0,1,.))
        {
		N1 = sum(weights)
                index = J(sum(weights),1,1)
                for(i=1;i<=N0;i++)
                {
                        j=0
                        while(j++ < weights[i])
                                index[++k] = i
                }
        }
        else
	{
		N1 = N0
		index = 1::N0
	}

	index = index\index

	// Getting the selected obs id
        permut = index[order(runiform(N1*2,1),1)[1::n]]

	// Creating the weights
	newsample = J(N0,1,0)
	for(i=1;i<=n;i++)
		newsample[permut[i]] = newsample[permut[i]] + 1
		

	return(newsample)

}

end
