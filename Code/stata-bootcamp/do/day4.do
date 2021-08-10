/* 

	SUMMARY: This do file produces a set of graphics from the US-Census, Barro-Lee, 
	and WDI datasets used earlier in this course. 
	
*/

/* AA Note: Wanted to add the dta file and other paths*/

// preliminiaries 
clear 
set more off 
set scheme s2color // default 

if "`c(username)'" == "julianduggan" {
	global root "/Users/julianduggan/Dropbox/CGD-training/stata-bootcamp"
}

if "`c(username)'" == "jduggan" {
	global root "S:/Dropbox/CGD-training/stata-bootcamp"
}

global input 	"$root/Data/input"
global dofile	"$root/do"
global output 	"$root/Data/output"
global graph	"$root/output/figures"
cd "$root"


// help 
* NOTE: In general, there are way too many options for making graphs to be worth
* memorizing. There are some basics worth remembering, but refer to help files often.

help graph 

// import 
use "$output/acs17_comb.dta", clear 

// scatter 
	
	// clean 
	gen id = _n 
	drop id2
	ta id 
	* ssc install labutil
	labmask id, values(state)

	// simple - no options
	scatter married_perc id 
	
	graph export "$graph/simple.png", replace 
	
	// simple - new scheme 
	* Advice: ALWAYS use set scheme s1mono. The stata default is repulsive. 
	set scheme s1mono
	scatter married_perc id 
 

	// discuss: what are some things that are wrong with that graph? 
	
	// prettier #1 - options
	scatter married_perc id, title("Percent Married")
	
	
	// prettier #2 - multiple options
	scatter married_perc id, title("Percent Married") xti("") yti("") ysc(r(0 100)) ///
	ylab(0 (20) 100) mcol(midblue) msym(oh) msize(small) // help colorstyle
														 // help symbolstyle
										                 // help markersizetyle	
														 
	// prettier #3 - options and suboptions	
	scatter married_perc id, title("Percent Married", size(medium) margin(small)) ///
	xti("") yti("") ysc(r(0 100)) mcol(midblue) msym(oh) msize(small) ///
	ylab(0 (20) 100) xlab(1 (1) 52, valuelabels labs(tiny) angle(45))
	
	graph export "$graph/pretty.png", replace 
	
	// general point: every graph you make should have a point it tries to make. 
	// in other words, each should answer a specific question. 
	
	// informative and prettier #1 
	sort married_perc
	gen m_id = _n
	labmask m_id, values(state)
	
	scatter married_perc m_id, title("Percent Married", size(medium) margin(small)) ///
	xti("") yti("") ysc(r(0 100)) mcol(midblue) msym(oh) msize(small) ///
	ylab(0 (20) 100) xlab(1 (1) 52, valuelabels labs(tiny) angle(45))
	

	// informative and prettier #2 
	su married_perc
	loc avg_married_perc = `r(mean)'
	di `avg_married_perc'
	
	scatter married_perc m_id, title("Percent Married", size(medium) margin(small)) ///
	xti("") yti("") ysc(r(0 100)) mcol(midblue) msym(oh) msize(small) ///
	ylab(0 (20) 100) xlab(1 (1) 52, valuelabels labs(tiny) angle(45)) ///
	yline(`avg_married_perc', lcol(red))
	
	graph export "$graph/informative1.png", replace 

// graph twoway 
	
	// scatter if
	scatter married_perc m_id if region == "South"
	
	// graph twoway -- overlay 2 graphs
	graph twoway (scatter married_perc m_id if region == "South") /// 
	(scatter married_perc m_id if region == "West" )
	
	// graph twoway -- overlay 4 graphs
	ta region 
	
	graph twoway (scatter married_perc m_id if region == "South") /// 
	(scatter married_perc m_id if region == "West" ) ///
	(scatter married_perc m_id if region == "North" ) ///
	(scatter married_perc m_id if region == "Midwest" )

	// common problem: STATA defaults look bad. 
	// solution: you go one-by-one fixing issues using options
	
	// graph twoway -- overlay 4 graphs pretty
	graph twoway (scatter married_perc m_id if region == "South", msym(circle) mcol(red)) /// 
	(scatter married_perc m_id if region == "West", msym(circle) mcol(gold)) ///
	(scatter married_perc m_id if region == "East", msym(circle) mcol(blue)) ///
	(scatter married_perc m_id if region == "Midwest", msym(circle) mcol(purple))
	
	// graph twoway -- overlay 4 graphs prettier
	* note: Just added our options from above back in, minus msym and mcol
	graph twoway (scatter married_perc m_id if region == "South", msym(circle) mcol(red)) /// 
	(scatter married_perc m_id if region == "West", msym(circle) mcol(gold)) ///
	(scatter married_perc m_id if region == "East", msym(circle) mcol(blue)) ///
	(scatter married_perc m_id if region == "Midwest", msym(circle) mcol(purple)), ///
	title("Percent Married", size(medium) margin(small)) ///
	xti("") yti("") ysc(r(0 100))  ///
	ylab(0 (20) 100) xlab(1 (1) 52, valuelabels labs(tiny) angle(45))
	
	// graph twoway -- overlay 4 graphs prettier -- legend
	* note: Just added our options from above back in, minus msym and mcol
	graph twoway (scatter married_perc m_id if region == "South", msym(circle) mcol(red)) /// 
	(scatter married_perc m_id if region == "West", msym(circle) mcol(gold)) ///
	(scatter married_perc m_id if region == "East", msym(circle) mcol(blue)) ///
	(scatter married_perc m_id if region == "Midwest", msym(circle) mcol(green)), ///
	title("Percent Married", size(medium) margin(small)) ///
	xti("") yti("") ysc(r(0 100))  ///
	ylab(0 (20) 100) xlab(1 (1) 52, valuelabels labs(tiny) angle(45)) ///
	legend(lab(1 "South") lab(2 "West") lab(3 "East") lab(4 "Midwest"))

	graph export "$graph/informative2.png", replace 

// discuss / exercise: what are some questions you might want to answer with these
// data? browse the dataset to remember what variables we have. brainstorm some
// types of scatterplots that could answer these questions.

// conclusion: there are a million other types of graphs you can make in STATA. see options 
// available at: help twoway 
