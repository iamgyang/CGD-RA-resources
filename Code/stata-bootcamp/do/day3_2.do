*** Alysha Gardner
*** 6/19/19
** Lesson three - basic linear regression and exporting tables

**Challenge #1: Challenge #1: Run a regression of your WDI outcome of choice on education, with fixed effects controls for World Bank regions. 

*Step 1: Set directory and input data
	global root	"C:\Users\user\Dropbox\CGD\Projects\CGD-Data-Repository\Code\stata-bootcamp"
	global input	"$root/Data/input"
	global dofile 	"$root/do"
	global output	"$root/Data/output"
	global graphs	"$root/output/figures"
	cd "$root"

use "$output/bl_wdi.dta", clear 
	
*Step 2: basic regression without controls
reg female_lf yr_sch

*Step 3: convert region_code into a numerical variable
rename region_code region_codestrg
encode region_codestr, generate (region_code)

*(Step 3.5: check to make sure everything looks good with the new variable)
codebook region_code

*Step 4: Define the panel
*(When defining by region, you won't need to add years because there will be multiple examples of the same year within one regional category)
xtset region_code

*Step 5: Regression with fixed controls by region
xtreg female_lf yr_sch i.region_code, fe




