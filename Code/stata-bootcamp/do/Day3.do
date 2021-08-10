*** Alysha Gardner
*** 6/19/19
** Lesson three - basic linear regression and exporting tables

//Set directory

	global root	"C:\Users\user\Dropbox\CGD\Projects\CGD-Data-Repository\Code\stata-bootcamp"
	global input	"$root/Data/input"
	global dofile 	"$root/do"
	global output	"$root/Data/output"
	global graphs	"$root/output/figures"
	cd "$root"
	
***Import merged dataset from yesterday
use "$output/bl_wdi.dta", clear 	

*Linear regression allows you to understand the relationship between 2 variables
*Terminiology: Regress ____ on ____
			  *Regress dependent variable on independent variable
			  *Regress y axis on x axis

**create scatterplot
twoway (scatter gdp_pc lhc)

*Linear regression creates a best fit line to match the data
** create scatterplot with best fit line
twoway (scatter gdp_pc lhc) (lfit gdp_pc lhc)

*the most basic type of regression is OLS, which minimizes the sum of the squares of the errors
***http://setosa.io/ev/ordinary-least-squares-regression/ 

*Run a basic regression for two different independent variables
regress gdp_pc lhc
reg gdp_pc lhc
reg gdp_pc lu

***https://www.princeton.edu/~otorres/Regression101.pdf
*Instructions on how to interpret the table 

*you can also add controls to a regression
reg gdp_pc lhc pop
drop ln_gdp_pc
gen ln_gdp_pc = ln(gdp_pc)
gen ln_lhc = ln(lhc)
label variable ln_gdp_pc "log(GDP per capita (constant))"
label variable ln_lhc "log(% completed tertiary education)"
twoway (scatter ln_gdp_pc ln_lhc) (lfit ln_gdp_pc ln_lhc)
*https://twitter.com/nickchk/status/1068215492458905600

*One control that may be worth examining is by WB lending categories
reg gdp_pc lhc region_code
sum region_code, detail
summarize region_code, detail
summa region_code, detail
describe region_code
codebook region_code

*Because its a string, we want to re-code it for analysis
rename region_code region_codestr
encode region_codestr, generate (region_code)
codebook region_code

*Now lets look at the regression again
regress gdp_pc lhc region_code
regr gdp_pc lhc region_code //BAD ONE! (1-5)
reg gdp_pc lhc i.region_code //GOOD ONE! (actual levels)
*Notice how many regions are shown
*Notice the R-squared and adjusted R-squared values, compare to original regression
reg gdp_pc lhc

*Adding another element to our regression: fixed-effects
*Panel dataset - what is it?

xtset
help xtset
xtset country year
rename country countrystr
encode countrystr, generate (country)
xtset country year

*Fixed-effects regression (fixed for country effects)
xtreg gdp_pc lhc i.region_code, fe	
reg gdp_pc lhc i.region_code i.country


***Use fixed-effects (FE) whenever you are only interested in analyzing the impact of variables that vary over time. FE explore the relationship between predictor and outcome variables within an entity (country, person, company, etc.). Each entity has its own individual characteristics that may or may not influence the predictor variables ... When using FE we assume that something within the individual may impact or bias the predictor or outcome variables and we need to control for this. FE remove the effect of those time-invariant characteristics so we can assess the net effect of the predictors on the outcome variable.
*** https://www.princeton.edu/~otorres/Panel101.pdf 

clear 

***Challenge #1: Run two regressions of your WDI outcome of choice on education, one without controls and one with fixed effects controls for World Bank regions.

***Challenge #2: Run a regression of your WDI outcome of choice on education, with fixed effects controls for lending category. 


