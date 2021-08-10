/*==============================================================================
AUTHOR: 	Aisha Ali

SUMMARY: 	Originally created for the Gender/Education RA hiring process 
			which included a Stata test. Current version altered for Day 2 of 
			the Summer Delegates' Stata bootcamp.

PURPOSE: 	This do file imports, cleans, merges, and analyzes two datasets --
			one from the World Bank (World Dev. Indicators) and the other from
			Barro-Lee Educational Attainment project. 
			
OUTPUTS: 	wdi.dta			|	World Development Indicators (cleaned, reshaped)
			wdi_lending.dta	| 	WDI + Lending group information
			barro_lee.dta	|	Barro-Lee Educational Attainment (cleaned)
			bl_wdi.dta		|	Merged Dataset
	
	
DATA SOURCES: 	World Bank, Barro-Lee 
DATA LINKS:		https://databank.worldbank.org/data/source/world-development-indicators
				http://www.barrolee.com/
DOWNLOAD DATE:	2 April 2019

==============================================================================*/


clear
set more off

///Set directory
	if "`c(username)'" == "aali" {
		global root 	"C:/Users/aali.CGDEV/CGD Education Dropbox/Aisha Ali/CGD-training/stata-bootcamp"
	}

	global input 	"$root/Data/input"
	global dofile	"$root/do"
	global output 	"$root/Data/output"
	global graphs	"$root/output/figures"
	cd "$root"

///import WDI data
	import delimited "$input/WDI - Barro Lee/wdi_gdp_lfp.csv", varnames(1) rowrange(:652)  clear

	//destring numerical variables
		foreach q of varlist yr* {
			replace `q' = "" if `q' == ".."
			destring `q', replace
			}

	//replace seriesname with future variable names
		replace seriesname = "gdp_pc" if seriescode == "NY.GDP.PCAP.KD"
		replace seriesname = "male_lf" if seriescode == "SL.TLF.CACT.MA.ZS"
		replace seriesname = "female_lf" if seriescode == "SL.TLF.CACT.FE.ZS"

	//rename variables discus
		rename (ïcountryname seriesname) (country series)
		encode series, gen(sercode)
		drop seriescode
		
	//reshape
		reshape long yr, i(country series) j(year) //wide to long (so years are values in one variable)
		reshape wide yr series, i(country year) j(sercode) //long to wide (lfp_f lfp_m gdp are 
	
	//rename new variables
		drop series*
		rename yr1 female_lf
		rename yr2 gdp_pc
		rename yr3 male_lf
		rename countrycode WBcode
	
	//label variables
		la var country "Country Name"
		la var year "Year"
		la var female_lf "Labor force participation rate, female"
		la var male_lf "Labor force participation rate, male"
		la var gdp_pc "GDP per capita (constant 2010 US$)"
		la var WBcode "WB Code"

	
	save "$output/wdi.dta", replace
	
clear
///import Lending Group data	
	import excel using "$input/WDI - Barro Lee/lending_groups.xlsx", firstrow clear
	drop Other Region Incomegroup
	rename (Economy Code Lendingcategory) (country WBcode lending)
		replace lending = subinstr(lending, "..","",.)
	
	mmerge WBcode using "$output/wdi.dta"
	drop if _merge==1
	drop _merge
	
	save "$output/wdi_lending.dta", replace

	clear
	
///import Barro-Lee educational attainment dataset
	use "$input/WDI - Barro Lee/BL2013_MF1599_v2.2.dta"
		
	//fix WBcodes
		replace WBcode = "MDA" if country=="Republic of Moldova"
		replace WBcode = "SRB" if country=="Serbia"
		
		save "$output/barro_lee.dta", replace
		
	///merge with WDI data	
		merge 1:1 WBcode year using "$output/wdi_lending.dta"

	///restrict years to 1980 - 2010, every 5 years
		drop if year < 1980

	///restrict countries to countries that successfully merged
		keep if _merge==3
		drop _merge
	
	
	save "$output/bl_wdi.dta", replace
