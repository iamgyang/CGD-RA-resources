*** Alysha Gardner
*** 6/19/19
** Lesson three - basic linear regression and exporting tables

**Challenge #1: Run a regression of your WDI outcome of choice on education, with fixed effects controls for lending category. (Bonus: update the lending categorical data with xxxxx file) 

*Step 1: Set directory and input data
	global root	"C:\Users\user\Dropbox\CGD\Projects\CGD-Data-Repository\Code\stata-bootcamp"
	global input	"$root/Data/input"
	global dofile 	"$root/do"
	global output	"$root/Data/output"
	global graphs	"$root/output/figures"
	cd "$root"

use "$output/bl_wdi.dta", clear 

*Step 2: convert lending into a numerical variable
rename lending lendingstr
encode lendingstr, generate (lending)

*(Step 2.5: check your new variable)
codebook lending
gsort country year
order lending, after (year)
browse

*Step 3: Add category for missing values and re-encode
replace lending="Non-borrowing country" if missing(lending)
codebook lending
encode lending, generate (lending_final)

*Step 4: Define the panel
xtset lending_final

*Step 5: Regression with fixed controls by lending category
xtreg female_lf yr_sch i.lending_final, fe

*Why might this be problematic?
*(Because lending categories traditionally aren't fixed over time, though they are in this dataset)



