capture program drop run_regression
program run_regression
	syntax Growth levels, var(namelist) [best(name) outfile(string)]
	if "`growth'" == "" {
		regress `best' `var'
		esttab using "`outfile'", replace	    
	}
	else if "`growth'" != "" {
	    di "hahaha"
	}
end

sysuse auto, clear
run_regression growth, best(price) var(mpg headroom) outfile("test.tex")

