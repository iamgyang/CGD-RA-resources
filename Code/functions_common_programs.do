// checks if IDs are duplicated
quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

// drops all missing observations
quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

// creates new variable of ISO3C country codes
quietly capture program drop conv_ccode
program conv_ccode
args country_var
	capture confirm variable iso3c
	// 	0 == it's there
	// 	111 == it's not there:
	if _rc == 0 {
		display as error "{p}Hello there! Unfortunately you already have a variable named 'iso3c'. Please change this variable name or delete it."
		exit 498
	}
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso3c)
end

conv_ccode make

// create a group of logged variables
quietly capture program drop create_logvars
program create_logvars
args vars

foreach i in `vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}
end

// get a random sample of something, potentially by groups
// currently only accepts 1 group var:
quietly capture program drop rand_samp
program rand_samp
	args group_vars N_to_get proportion_or_nrow
	
	clear
	sysuse auto
	local group_vars "foreign"
	local N_to_get 50
	local proportion_or_nrow "rows"
	
	local count_values_num: word count `group_vars'
	di "`count_values_num'"

	if (`count_values_num' != 1 & `count_values_num' != 0) {
		display as error "{p}Sorry--we can only group by 1 variable at the moment"
		exit 498
	}
	
	// Get random number.
	// Sort on random number.
	// Get the number of levels of random number.
	// If we want a proportion, then get the number of rows below that 
	// proportion by group.
	// If we want an absolute total number of rows, then do a little bit 
	// more math: keep if the count is (N / number of levels)
	
	gen runif = uniform()
	sort runif
	
	if (`count_values_num' == 1) {
		local to_by_sort_or_not "bysort `group_vars': "
	}
	`to_by_sort_or_not' gen n = _n
		
	quietly tab `group_vars'
	local levels `r(r)'
	
	if ("`proportion_or_nrow'" == "prop") {
		`to_by_sort_or_not' gen N = _N
		gen prop = n / N
		keep if prop <= `N_to_get'
	}
	else if ("`proportion_or_nrow'" == "rows") {
		local group_N_cutoff = `N_to_get'/`levels'
		keep if n <= `N_to_get'/`levels'
	}
	
	drop n
	quietly capture drop N
end



















