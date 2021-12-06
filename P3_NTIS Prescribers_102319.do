


/**********************************************************
Name: NTIS Prescribers
Project: CA County Estimates of OUD	
Purpose: Process NTIS Prescriber data
Author: Marni Epstein
Date: February 2018
Updated: August 2019

Notes:
(1) Data Dictionary from NTIS can be found here: D:\Users\Mepstein\Box Sync\2017 OUD CHCF County Estimates\3 Data\NTIS DEA\NTIS CD\Record Layout March 2017.docx

(2) We use business activity codes/subcodes to determine who has a waiver. We pull the following people.
	Note: C indicates practitioner, MLP is mid-level practitioner. DW/# is Data waiver/waiver limit
		Business Activity Code C	Sub Code 1	Description – Practitioner – DW/30
		Business Activity Code M	Sub Code F	Description – MLP-Nurse Practitioner DW 30
		Business Activity Code M	Sub Code G	Description – MLP-Physician Assistant DW 30
		
		Business Activity Code C	Sub Code 4	Description – Practitioner – DW/100
		Business Activity Code M 	Sub Code H 	Description – MLP-Nurse Practitioner DW 100
		Business Activity Code M 	Sub Code I 	Description – MLP-Physician Assistant DW 100

		Business Activity Code C	Sub Code B	Description – Practitioner-DW/275


***********************************************************/

/******* 
temp: Marni's Mac
***********/

/*
*Enter user (computer name)
global user = "marniepstein"

*Enter today's date to create unique log
global today=072319

*Set directory and globals
cd "/Users/marniepstein/Box/2019 OUD CHCF County Estimates/3b Analysis 2019 Update/Datasets"
global deadata "/Users/marniepstein/Box/2019 OUD CHCF County Estimates/3 Data/NTIS DEA/July 2019 Data Download"
global crosswalk "/Users/marniepstein/Box/2019 OUD CHCF County Estimates/3 Data/Geographic Crosswalks/2017"
global cures "/Users/marniepstein/Box/2019 OUD CHCF County Estimates/3 Data/CURES/2018"
*/

******************************************************************************************

*Enter user (computer name)
global user = "MEpstein"

*Enter today's date to create unique log
global today=102319

*Set directory and globals
cd "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Datasets"

global deadata "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\NTIS DEA\July 2019 Data Download"
global crosswalk "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\Geographic Crosswalks\2017"
global cures "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\CURES\2018"
global pop "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\CDC Wonder Bridged-Race Population Estimates\2018"

global output "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Output"
global log "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Logs"

log using "${log}/P3_NTIS Prescribers_${today}.log", replace



use "${deadata}\ca_rawdata.dta", clear

/**************************************************
*Create variable for whether they have a DATA waiver
**************************************************/

*Concatenate business activity code and sub-code
gen bacsc = BusinessActivityCode + BusinessActivitySubCode

*Indicator (0/1) for if have a bup waiver
gen waivered = 0
*Waiver limit, missing if no waiver
gen waiverlimit =.

* 30-waiver limit
replace waivered = 1 if inlist(bacsc, "C1", "MF", "MG")
replace waiverlimit = 30 if inlist(bacsc, "C1", "MF", "MG")

* 100-waiver limit
replace waivered = 1 if inlist(bacsc, "C4", "MH", "MI")
replace waiverlimit = 100 if inlist(bacsc, "C4", "MH", "MI")

* 275-waiver limit
replace waivered = 1 if inlist(bacsc, "CB")
replace waiverlimit = 275 if inlist(bacsc, "CB")

*There are 3 prescribers that are listed twice in different counties
*Mark them as having a waiver limit of 15
duplicates report Name if waivered ==1 
duplicates tag Name if waivered ==1, gen(dup)

replace waiverlimit = 15 if dup == 1


rename ZipCode ZIP_CODE

*Merge with zip to county crosswalk

merge m:1 ZIP_CODE using "${crosswalk}/zip_county_crosswalk.dta"

* _m == 2 is zip code that doesn't match to a prescriber
drop if _m == 2

/***********************
*Check _m = 1, which are prescribers who don't match to a CA zip. Some may be entered incorrectly

Look these addresses up by hand (using google maps) and edit zip codes that were entered incorrectly
************************/
list if _m==1

replace State = "AZ" if RegistrationNumber == "FT1390412" //Correct zip code, state is wrong
replace ZIP_CODE = "91010" if RegistrationNumber == "FB7013965" // Zip code has two digits switched
replace ZIP_CODE = "91010" if RegistrationNumber == "MR2339162" // Zip code has two digits switched
replace ZIP_CODE = "92134" if RegistrationNumber == "FA7885619" // Zip code has one digit switched
replace ZIP_CODE = "92325" if RegistrationNumber == "FE8024414" // Zip code has one digit switched
replace City = "Crestline" if RegistrationNumber == "FE8024414" // Same entry as above, also has wrong city listed
replace ZIP_CODE = "92408" if RegistrationNumber == "BC5528483" // Zip code has one digit switched
replace ZIP_CODE = "92505" if RegistrationNumber == "AQ2258007" // Zip code has one digit switched
replace ZIP_CODE = "94143" if RegistrationNumber == "FT7459680" // Zip code has one digit switched
replace ZIP_CODE = "94158" if RegistrationNumber == "FH6458500" // Zip code has one digit switched
replace ZIP_CODE = "94143" if RegistrationNumber == "FS7430755" // Zip code has one digit switched
replace ZIP_CODE = "94143" if RegistrationNumber == "FC6125923" // Zip code has one digit switched


*Drop those from out of state and re-merge with corrected zips
drop if State != "CA"
drop ZCTA COUNTY ZPOPPCT countyname _merge

merge m:1 ZIP_CODE using "${crosswalk}/zip_county_crosswalk.dta"

*There should be no _m == 1. If so, correct the zip codes in the step above.
*Drop _m == 2, which are the zip codes with no corresponding prescribers
drop if _m == 2
drop _m
drop if RegistrationNumber == ""

*Map LA Zip Codes to SPAs.
rename ZCTA ZCTA1
label variable ZCTA1 "ZCTA from Zip to County crosswalk"

merge m:1 ZIP_CODE using "${crosswalk}/zip_SPA_crosswalk.dta"

/*******
_m == 1 are prescribers that are in a non-SPA county
_m == 2 are SPA zip codes that don't match to a prescriber.
Note that some prescribers from counties other than LA will match in this crosswalk. 
Since the crosswalk is created from census blocks to zip codes, it may capture zip codes outside of LA
We only use prescribers who are from Los Angeles, even if they match to a zip in the crosswalk.
**********/

tab countyname _m
tab countyname SPA, m

*Zips match to SPAs outside of LA. only keep SPAs from LA.
replace SPA = . if countyname != "Los Angeles"

*Replace countyname = "Los Angeles" to the name of the specific LA
replace countyname= "LA SPA " + string(SPA) if countyname=="Los Angeles"
replace countyname= "LA SPA 1 and 5" if countyname=="LA SPA 1" | countyname=="LA SPA 5"

tab countyname, m
drop _m

*Check the geocoding of bup-waivered prescribers
tab waivered, m
drop if RegistrationNumber == ""


* Export the waivered prescribers who are in split ZCTAs to check in R geocoding.
tab waivered splitZCTA

preserve
keep if waivered == 1
keep if splitZCTA != 0

export delimited "${deadata}/NTIS waivered CA prescribers split ZCTA.csv", replace
restore

/****** OLD. last time this only affected 4 prescribers. Hold off on this for now
*From R - when geocoding and crosswalk counties don't match up, use geocoding
replace countyname = "LA SPA 2" if RegistrationNumber == "FS3176333"
replace countyname = "Contra Costa" if RegistrationNumber == "FP7119212"
replace countyname = "Contra Costa" if RegistrationNumber == "BB1194404"
replace countyname = "Placer" if RegistrationNumber == "AM6705593"
**********/

*Sum number of prescribers with each waiver limit by county
gen NTISwaiver15 = waiverlimit == 15
gen NTISwaiver30 = waiverlimit == 30
gen NTISwaiver100 = waiverlimit == 100
gen NTISwaiver275 = waiverlimit == 275

gen prescriber = 1 //Assign 1 to everyone to count total prescribers in collapse

/********************************
Print list of bup prescribers for CHCF
********************************/
preserve

keep if waiverlimit != . //only print bup prescribers
keep Name Address1 Address2 City State ZIP_CODE waiverlimit countyname
order countyname
sort countyname Name
rename countyname County
rename ZIP_CODE Zipcode

export excel using "${deadata}\Buprenorphine Prescriber List California.xlsx",  replace firstrow(variables)

restore

/********************************
Collapse to the county level
********************************/
collapse (sum) NTISwaiver15 NTISwaiver30 NTISwaiver100 NTISwaiver275 waivered prescriber, by(countyname)

*Check if sums add up to total
gen checktot = NTISwaiver15 + NTISwaiver30 + NTISwaiver100 + NTISwaiver275
list if checktot != waivered
drop checktot

rename countyname county
rename waivered bupwaivproviders

label variable NTISwaiver15 "Prescribers with a 30-waiver limit who are registed in 2 counties(NTIS DEA)"
label variable NTISwaiver30 "Prescribers with a 30-waiver limit (NTIS DEA)"
label variable NTISwaiver100 "Prescribers with a 100-waiver limit (NTIS DEA)"
label variable NTISwaiver275 "Prescribers with a 275-waiver limit (NTIS DEA)"
label variable bupwaivproviders "Buprenorphine-Waivered Prescibers (NTIS DEA)"
label variable prescriber "All Prescribers (NTIS DEA)"

save "ntis_county.dta", replace

/****************
Add in CURES Data
Note that the CURES data only has LA as one county but our data has LA split but SPAs
****************/

tempfile temp1
save "`temp1'"
import excel using "${cures}\Urban Institute Request - CA Prescriber data from CURES_2018 9.10.19v2.xlsx", firstrow cellrange(A3:E61) sheet("Prescriber Data") clear
rename PrescribersofBupe bupprx_byprxcounty
rename AllPrescribers allprx_byprxcounty
rename D bupprx_bypatcounty
rename E allprx_bypatcounty
gen county=strproper(County)
drop County

label variable bupprx_byprxcounty "Buprenorphine-Waivered Prescibers, by Prescriber County (CURES)"
label variable allprx_byprxcounty "All Prescibers, by Prescriber County (CURES)"
label variable bupprx_bypatcounty "Buprenorphine-Waivered Prescibers, by Patient County (CURES)"
label variable allprx_bypatcounty "All Prescibers, by Patient County (CURES)"

replace county="San Luis Obispo" if county=="San Luis Obisp"
merge 1:1 county using "`temp1'"
drop _m


/****************
Add in new cut of patients per prescriber
****************/

tempfile temp1
save "`temp1'"
import excel using "${cures}\Urban Institute Request - CA Prescriber data from CURES_2018 9.10.19v2.xlsx", firstrow cellrange(A2:H62) sheet("Buprenorphine Patients") clear
rename A County
gen county=strproper(County)
drop County
order county

drop if county == ""
drop B //total bupe prescribers, same as bupprx_byprxcounty from above

rename TotalBuprenorphinePatientsby avg_buppat_perprx
label variable avg_buppat_perprx "Average Unique Bupe Patients per Prescriber by Prescriber County, all patients"

rename D tot_buppat_byprxcounty
label variable tot_buppat_byprxcounty "Total Unique Buprenorphine Patients by Prescriber County, all patients"

rename InCountyBuprenorphinePatients avg_buppat_perprx_incounty
label variable avg_buppat_perprx_incounty "Average Unique Bupe Patients per Prescriber by Prescriber County, in county patients"

rename F tot_buppat_byprxcounty_incounty
label variable tot_buppat_byprxcounty_incounty "Total Unique Buprenorphine Patients by Prescriber County, in county patients"

rename OutofCountyBuprenorphinePati avg_buppat_perprx_outcounty
label variable avg_buppat_perprx_outcounty "Average Unique Bupe Patients per Prescriber by Prescriber County, out of county patients"

rename H tot_buppat_byprxcounty_outcounty
label variable tot_buppat_byprxcounty_outcounty "Total Unique Buprenorphine Patients by Prescriber County, out of county patients"


*destring and format numbers
destring, replace
format avg_buppat_perprx tot_buppat_byprxcounty avg_buppat_perprx_incounty tot_buppat_byprxcounty_incounty avg_buppat_perprx_outcounty tot_buppat_byprxcounty_outcounty %12.1g

merge 1:1 county using "`temp1'"
drop _m

*Compared CURES number to the DEA total
list county bupwaivproviders bupprx_byprxcounty

*Export list of DEA vs CURES prescribers
preserve
keep county bupwaivproviders prescriber bupprx_byprxcounty allprx_byprxcounty
export excel using "${output}/CA Prescriber Data.xlsx", firstrow(varlabels) replace
restore

*Merge in SPA population counts and percentages
tempfile temp1
save "`temp1'"
	import excel using "${pop}\Urban Institute Request - 2018 Population Counts by SPA_9.9.19_variable names.xlsx", firstrow cellrange(A1:C8) clear
	rename SPA county
	rename Percent SPA_percent
	rename Population SPA_population
merge 1:1 county using "`temp1'"
drop _m SPA_population

/*** Out of County Prescribesr from CURES - number of prescribers from another county who prescribe to patients in this county ***/
gen prov_outofcounty = bupprx_bypatcounty - bupprx_byprxcounty
label variable prov_outofcounty "Number of out of county prescribers who prescribe in the county (CURES)"

* There are 485 out-of-county prescribers in LA
list county prov_outofcounty allprx_byprxcounty bupprx_byprxcounty if county == "Los Angeles"
preserve
keep if county == "Los Angeles"
gl LA_prov_outofcounty = prov_outofcounty[1]
gl LA_allprx_byprxcounty = allprx_byprxcounty[1]
gl LA_bupprx_byprxcounty = bupprx_byprxcounty[1]
di "$LA_prov_outofcounty $LA_allprx_byprxcounty $LA_bupprx_byprxcounty"
restore

* We divide these up among the LA SPAs, weighting by total bup-waivered prescribers from the NTIS DEA data (variable: bupwaivproviders)
egen LA_bupe_prescribers = total(bupwaivproviders) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
gen LA_bupe_prescribers_perc = bupwaivproviders / LA_bupe_prescribers if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

*Divide out of county prescribers, all prescribers (CURES), and bupe prescribers (CURES)
replace prov_outofcounty = ceil($LA_prov_outofcounty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace allprx_byprxcounty = ceil($LA_allprx_byprxcounty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace bupprx_byprxcounty = ceil($LA_bupprx_byprxcounty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

list county NTISwaiver30 NTISwaiver100 NTISwaiver275 bupwaivproviders prov_outofcounty


*Change missings to 0s
replace prov_outofcounty = 0 if prov_outofcounty == .
replace allprx_byprxcounty = 0 if allprx_byprxcounty == .

list county NTISwaiver30 NTISwaiver100 NTISwaiver275 prov_outofcounty bupwaivproviders bupprx_byprxcounty


/******************************************
Previously, if the CURES number of bupe prescribers was bigger than the DEA NTIS number, we inflated to CURES
We don't do this anymore because of concerns that the CURES numbers contain prescribers that prescribe bupe for pain and don't have an X-waiver
******************************************/


/****************************************************************
Add in buprenorphine patiet data from CURES
****************************************************************/
tempfile temp1
save "`temp1'"

import excel using "${cures}\Urban Institute Request - Buprenorphine Patients 09.19.19.xlsx", firstrow cellrange(A2:G60) sheet("By Patient County") clear
rename A county
replace county=strproper(county)

rename Total totbuppat_bypatcty
label variable totbuppat_bypatcty "Total bupe patients, by patient county"

rename WithatLeast1InCountyPrescr buppatincty_bypatcty
label variable buppatincty_bypatcty "Bupe patients with at least 1 in county prescriber, by patient county"

rename WithatLeast1OutCountyPresc buppatoutcty_bypatcty
label variable buppatoutcty_bypatcty "Bupe patients with at least 1 out of county prescriber, by patient county"

rename WithOnlyInCountyPrescribers buppatonlyincty_bypatcty
label variable buppatonlyincty_bypatcty "Bupe patients with only in county prescribers, by patient county"

rename WithOnlyOutsideCountyPrescri buppatonlyoutcty_bypatcty
label variable buppatonlyoutcty_bypatcty "Bupe patients with only out of county prescribers, by patient county"

rename WithBothInandOutCountyPres buppatinandout_bypatcty
label variable buppatinandout_bypatcty "Bupe patients with both in and out of county prescribers, by patient county"

merge 1:1 county using "`temp1'"
drop _m

* Divide up bup patients throughout LA, weighting by number of total prescribers (From DEA), same as above
list county totbuppat_bypatcty buppatincty_bypatcty buppatoutcty_bypatcty buppatonlyincty_bypatcty buppatonlyoutcty_bypatcty buppatinandout_bypatcty if county == "Los Angeles"
preserve
keep if county == "Los Angeles"
gl LA_totbuppat_bypatcty = totbuppat_bypatcty[1]
gl LA_buppatincty_bypatcty = buppatincty_bypatcty[1]
gl LA_buppatoutcty_bypatcty = buppatoutcty_bypatcty[1]
gl LA_buppatonlyincty_bypatcty = buppatonlyincty_bypatcty[1]
gl LA_buppatonlyoutcty_bypatcty = buppatonlyoutcty_bypatcty[1]
gl LA_buppatinandout_bypatcty = buppatinandout_bypatcty[1]
di "$LA_totbuppat_bypatcty $LA_buppatincty_bypatcty $LA_buppatoutcty_bypatcty $LA_buppatonlyincty_bypatcty $LA_buppatonlyoutcty_bypatcty $LA_buppatinandout_bypatcty"
restore

*Distribute to LA SPAs
replace totbuppat_bypatcty = ceil($LA_totbuppat_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buppatincty_bypatcty = ceil($LA_buppatincty_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buppatoutcty_bypatcty = ceil($LA_buppatoutcty_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buppatonlyincty_bypatcty = ceil($LA_buppatonlyincty_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buppatonlyoutcty_bypatcty = ceil($LA_buppatonlyoutcty_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buppatinandout_bypatcty = ceil($LA_buppatinandout_bypatcty * LA_bupe_prescribers_perc) if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

save "NTIS_final.dta", replace



/****************************************************************
* Add in treatment capacity with three different possible counts.
* We assume out-of-county prescribers always treat half as many as in-county 30-waivered prescribers
****************************************************************/
use "NTIS_final.dta", replace

order county
sort county

replace prov_outofcounty=0 if prov_outofcounty==.

/********
Total unique bupe patients who receive treatment in county: 104222
Total unique bupe patients who receive treatment out of county: 30172
Total X-waivered bupe prescribers in CA: 6515
Average in-county patients per prescriber = 104222 / 6515 = 16.00
Average out-of-county patients per prescriber = 30172 / 6515 = 4.6
o
Unique bupe patient numbers from
Box\2019 OUD CHCF County Estimates\3 Data\CURES\2018\Urban Institute Request - Buprenorphine Patients 09.19.19
********/
list bupwaivproviders if county == "California"
total bupwaivproviders

*We use current treatment for the lower bound estimate

* 3: 30-waivers treat 30, 100 and 275 treat at half capacity. 
* For the 3  30-waivers who are registered in 2 counties, we assume they can go up to 15
gen treatcap3bup = ceil(NTISwaiver15*15 + NTISwaiver30*30 + NTISwaiver100*50 + NTISwaiver275*137.5) 
label variable treatcap3bup "Buprenorphine Treatment Capacity if 30-waiver treat 30, 100 and 275 treat half limit"

replace treatcap3bup = 0 if treatcap3== .

*Add the 30-waivers who are registed in 2 counties to the list of 30 waivers and delete the waiver 15 variable
replace NTISwaiver30 = NTISwaiver30 + NTISwaiver15
drop NTISwaiver15

save "prescriber_DEA_numbers.dta", replace

log close


