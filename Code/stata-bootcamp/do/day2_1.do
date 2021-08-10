/*==============================================================================
AUTHOR: 	Aisha Ali

SUMMARY: 	Created for Day 2 of the Summer Delegates' Stata bootcamp. 

PURPOSE: 	This do file imports & merges two separate CSVs from the 2017 ACS. 
			
OUTPUTS: 	acspop.dta		|	Population by state (dta version of csv original)
			acsmarriage.dta |	Marriage stats by state (dta version)
			acs17_comb.dta	| 	Combined state-level marriage & population data.
	
	
DATA SOURCES: 	US Census Bureau - American Community Survey (ACS)
DATA LINKS:		https://www.census.gov/programs-surveys/acs
DOWNLOAD DATE:	15 May 2019

==============================================================================*/


clear
set more off

///Set directory
	if "`c(username)'" == "mariazipet" { 
		global root "/Users/mariazipet/CGD Education Dropbox/Aisha Ali/CGD-training/stata-bootcamp"
	}
	
	
	
	if "`c(username)'" == "aali" {
		global root 	"C:/Users/aali.CGDEV/CGD Education Dropbox/Aisha Ali/CGD-training/stata-bootcamp"
	}
	
	global input 	"$root/Data/input"
	global census	"$input/US Census"
	global dofile	"$root/do"
	global output 	"$root/Data/output"
	global graphs	"$root/output/figures"
	cd "$root"
	
	
///import ACS population statistics
	import delimited "$census/acs_17_pop_stats.csv", clear //encoding not super important to know
	
	save "$output/acspop.dta", replace

	
///import ACS marriage statistics
	import delim "$census/acs_17_marital_stats.csv", varnames(1) encoding("utf-8") clear

	save "$output/acsmarriage.dta", replace
	

///merge population & marriage stats
	use "$output/acsmarriage.dta", clear
	merge 1:1 id2 using "$output/acspop.dta" //merge 1:1 is the easiest, lets start here
	
	//let's label the variables for our analysis later
		label variable married_perc "Percent of the population who are married"
		la var widow_perc "Percent of the population who are widowed"
		la var divorce_perc "Percent of the population who are divorced"
		la var sep_perc "Percent of the population who are separated"
		la var never_perc "Percent of the population who have never married"
		la var state "State"
		la var total_pop "Total Population"
		la var id2 "State ID"
	
	drop _merge	//example of dropping a variable
	keep married_perc widow_perc divorce_perc sep_perc never_perc state total_pop id2 //example of keeping specific variables
	
	order id2 state total_pop, first
	
	//Quiz - How many married people reside in Virginia?
	gen pop_married = (married_perc/100) * total_pop
		//Answer: 3,459,810
	//How many people are divorced or separated?
	gen sep_div = ((divorce_perc/100) * total_pop) + ((sep_perc/100) * total_pop)
	
	//georgia: 1,127,213 
//
	
//Generating Variables
generate region = "East" if state == "Connecticut" | state ==  "Maine" | state ==  "Massachusetts" | state ==  "New Hampshire" | state ==  "Rhode Island" | state ==  "Vermont" | state == "New Jersey" | state == "New York" | state == "Pennsylvania"
//Replacing Values 
replace region =  "Midwest" if state == "Illinois" | state == "Indiana" | state == "Michigan" | state == "Ohio" | state == "Wisconsin" | state == "Iowa" | state == "Kansas" | state == "Minnesota" | state == "Missouri" | state == "Nebraska" | state == "North Dakota" | state == "South Dakota"
replace region = "West" if state == "Arizona" | state == "Colorado" | state == "Idaho" | state == "Montana" | state == "Nevada" | state == "New Mexico" | state == "Utah" | state == "Wyoming" | state == "Alaska" | state == "California" | state == "Hawaii" | state == "Oregon" | state == "Washington"
replace region = "South" if state == "Delaware" | state == "Florida" | state == "Georgia" | state == "Maryland" | state == "North Carolina" | state == "South Carolina" | state == "Virginia" | state == "District of Columbia" | state == "West Virginia" | state == "Alabama" | state == "Kentucky" | state == "Mississippi" | state == "Tennessee" | state == "Arkansas" | state == "Louisiana" | state == "Oklahoma" | state == "Texas"

//Encoding 
encode region, generate(reg_code)

//Recoding
recode reg_code (1=2) (2=3) (3=4) (4=1)

//Labeling Variables
label variable region "Region"
label variable reg_code "Regional Code"

//Labeling Values
	label define reglab 2 "Northeast" 3 "Midwest" 4 "South" 1 "West"
	label value reg_code reglab

	
	save "$output/acs17_comb.dta", replace
	
	//How many people are separated or divorced?
	
	
	
	
