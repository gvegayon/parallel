program secondary_output
	syntax, output_make(string) blank(string) [output_price(string)]
	set trace on
	set tracedepth 1
	preserve
	
	keep make
	if ($pll_instance == 1) save `output_make'
	restore
	preserve
	
	if "`output_price'"!=""{
		keep price
		//save `output_price'
		restore
		keep mpg
	}
end
