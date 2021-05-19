// ============== SETUP ==============

*** install kountry, estoout, and findname packages if not already
*** ssc install kountry, replace
*** ssc install estout, replace
*** ssc install findname, replace

// clear workspace
cls

// use up more computer memory for the sake of accurate numbers:
set type double, perm

*** ========== MACROS ============
foreach user in "`c(username)'" {
	global root "/Users/`user'/Dropbox/Charts/WB disbursements"
	global output "/Users/`user'/Dropbox/Charts/WB disbursements/output"
	global input "/Users/`user'/Dropbox/Charts/WB disbursements/data raw"
}

clear all
set more off 

// ======= IMPORT SNAPSHOT DATASET & CALCULATE FLOWS ============

foreach seg_ in "ibrd" "ida" {

import delimited "$input/historical_snapshots/`seg_'_raw_downloaded_2021-02-09.csv", clear bindquote(strict) 

// For these locations, we want to delete the projects, because they are not 
// directed towards specific countries:
// Eastern Africa
// Southern Africa
// Western Africa
// Yugoslavia, former
// World
// Caribbean

drop if inlist(country,"Eastern Africa","Southern Africa","Western Africa","Yugoslavia, former","World", "Caribbean")

// Since everything is in stocks right now, we get lagged values and calculate
// differences between the lagged values and the current values.

// Get lagged values for disbursement, commitment, and repayments on principal:
rename disbursed_amount             typedisb
rename original_principal_amount    typecomit
rename repaid_to_                   typerepay
rename end_of_period                period
rename project_id                   id
rename country_code                 code
rename board_approval_date			appr_date

drop if id==""
drop if inlist(code, "1F","1G","3A","3T","4M","4P","6C","7C","8S")

// STATA literally interpreted Namibia's ISO2 code as Not Available:
replace code = "NA" if country == "Namibia"

// Generate the date variable. Recall that this date is the END of the period
// that the world bank is disbursing / commiting money. i.e. if the date shows
// 2-1-2020, then the entry for that row would be the total amount of money the 
// bank disbursed PRIOR to 2-1-2020.

foreach var of varlist appr_date period {
rename  `var' `var'_temp
replace `var'_temp = substr(`var'_temp, 1, 10)
gen `var' = date(`var'_temp, "MDY")
format  `var' %td
drop `var'_temp
}

// for the variable of the approval date, make sure that it's the EARLIEST commitment
// date
sort id country
by id country: egen min_appr_date = min(appr_date)
format min_appr_date %td
drop appr_date

global id_vars country code id min_appr_date period

collapse (sum) typedisb typecomit typerepay, by($id_vars)

// Subtract prior values to get flows:
sort $id_vars

foreach i_ of varlist typedisb typecomit typerepay {
sort country id code period
by country id code: gen `i_'_l1 = `i_'[_n-1]
replace `i_'_l1 = 0 if `i_'_l1==.
replace `i_' = `i_' - `i_'_l1
drop `i_'_l1
}

gen all_zero = typedisb == 0 & typecomit == 0 & typerepay ==0
drop if all_zero ==1
drop all_zero

// reshape from wide to long
reshape long type, i($id_vars) j(typeBLAH, string)
rename (type typeBLAH) (amount type)
drop if amount==0
replace amount = round(amount, 0.0001)
gen abs_amt = abs(amount)

// global macro for sorting variables:
global sort_vars            code id type abs_amt period
global sort_vars_ndate      code id type

sort $sort_vars

save "$input/snapshot_`seg_'.dta", replace
clear
}

use "$input/snapshot_ibrd.dta"
append using "$input/snapshot_ida.dta", generate(bank_seg_temp)
tostring bank_seg_temp, gen(bank_seg)
replace bank_seg = "IBRD" if bank_seg_temp==0
replace bank_seg = "IDA" if bank_seg_temp==1
drop bank_seg_temp

gen yr=year(period)
gen mo=month(period)
gen day=day(period)

replace type = "Disbursement" if type == "disb"
replace type = "Commitment" if type == "comit"
replace type = "Repayment" if type == "repay"
// For cutting at specific dates, use this kind of syntax:
// before2010=(period<mdy(11,3,2010))

save "$input/snapshot_final.dta", replace

// that's it folks.