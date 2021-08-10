*** Sam Besse
*** 6/14/19
*** Lesson one of stata camp, learn the basics
// Anything here will not execute

/*
anything here will not execute
*/

*** do in console
di "CGD"
di "2+2=" 2+2 // Comments

*** pull up marriage dataset in console

*** once you run something once it's helpful to save it in a do file so you and others can replicate it
*** import marriage data, notice that the file ending is .dta
use "C:\Users\sbesse\Dropbox\CGD-training\stata-bootcamp\Data\input\US Census\marriage.dta", replace
*** stata doesn't care about /\ direction

*** The above message can be unwieldy because of the long filepath you can shorten filepaths using variables
*** two types globals and locals
*** as name suggests locals work only in the document while globals persist
global census "C:\Users\sbesse\Dropbox\CGD-training\stata-bootcamp\Data\input\US Census"
local census "C:\Users\sbesse\Dropbox\CGD-training\stata-bootcamp\Data\input\US Census"

*** put this in the console
/*
di "$census"
*/

*** now try this
/*
di "`census'"
*/


use "$census\marriage.dta", replace
use "`census'\marriage.dta", replace

*** open data to look at it
*** see that the numbers are black and the strings are red
*** click the blue ones and look at the box in the top this is a labeled variable


*** let's rename id2 because it doesn't make sense
rename id2 state_id

*** let's check that these add up to 100
gen total = married_perc+widow_perc+divorce_perc+sep_perc+never_perc

egen total2 = rowtotal(*perc) // the star here is accounting for any characters


*** help to see more options
/*
help egen
*/

*** this is how you drop
drop total2

******DATA VIEWING
*** list shows you the raw data
list

*** sum shows you a summary of all vars
sum

*** use if to list just one observation
list if state=="Utah" //note the double equal signs
***single equal signs are for assignment and double equal signs are for equivalence

***tab needs a variable
*** notice that you can abbreviate variables but be careful!
tab married

*** to show one specific observation
di married[1]

*** _N and _n
di _N
di total_pop[_N] // last observation

*** _n is the current observation number
list if _n <=5
tab married if _n <= 5

sort married // sort to see bottom 5 in married
tab married if _n <= 5

gsort - married // sort the other way
tab married if _n <= 5

sum married
sum married, d // d stands for detailed
bysort region: sum married //will show separate results by region. Many commands can be used with by
//note that this is a deceptive average, why?


***loops
*** for in stata is written foreach
foreach x of numlist 1/10{
di married[`x'] //notice how in a loop you write 
}
stop
*** we can loop over things that aren't numbers 
foreach state_name in "Utah" "Washington" "Maine" {
sum if state == "`state_name'" 
}

*** Let's see if there are more married people in Vermont or divorced people in California
gen divorce_raw = total_pop*divorce_perc / 100 // divided by 100 because the percents are above 1

***better yet let's do it in a loop
foreach var in sep married widow never{
gen `var'_raw = `var'_perc *total_pop /100
}

*** need to sort to get a consistent order
sort state_id

*** if statement
*** the if isn't meant to be used with individual variables
*** if you use if with a variable without an index it will default to index==one which is usually not helpful
if divorce_raw[36] > total_pop[46]{ 
di "New York has more divorced people than Vermont has people"
}
else{
di "Vermont has more people than New York has divorced people"
}
*** this doesn't cover all cases because they could be equal


***Assign
*** Find the true nationwide married percent
*** fizzbang!

/*
*** scatter is the quickest way to graph
scatter married_perc divorce_perc //can't use abbreviations any more

*** reg is the quickest way to reg
reg married_perc divorce_perc
*/



*** global out C:\Users\sbesse\Dropbox\CGD-training\stata-bootcamp\Data\output\US Census
*** lastly save this dataset in stata format
***save "$out/marriage.dta", replace // the replace allows it to overwrite other things


