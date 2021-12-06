/**********************************************************
Name: OUD Counts
Project: CA County Estimates of OUD	
Purpose: Project OUD by county. We only have OUD rates by substate, but other independent variables by county. 
	Create a model to use to estimate county OUD rates.
Author: Marni Epstein
Date: September 2017
Update: April 2019

***********************************************************/

clear

*Enter user (computer name)
*global user = "EWiniski"
global user = "MEpstein"
*global user = "LBasurto"

*Enter today's date to create unique log
global today=030420

*Set directory and globals
cd "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Datasets"

global dashboard "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\CA Opioid Overdose Surveillance Dashboard\2018 Crude Rates"
global pop "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\CDC Wonder Bridged-Race Population Estimates\2018"
global oud "D:\Users\mepstein\Box\2019 OUD CHCF County Estimates\3 Data\NSDUH CA data"

global output "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Output"
global log "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Logs"

*Turn log on
cls
log using "${log}\OUD Counts Program.log", replace


/************************************************
Read in OUD estimates
************************************************/

import excel using "${oud}\CA Substate Rx OUD Percentages 2019 Update.xlsx", firstrow cellrange(A1:C30) clear
label variable RxMisuse_2012_2014 "2012-2014 Rx Misuse rate"

/************************************************
Inflate substate opioid misuse rates by the increase in the CA rate in the 2016-2017 combined NSDUH
2016-2017 CA Rx misuse rate: 4.3, from Table 12 from Box/2019 OUD CHCF County Estimates/3 Data/NSDUH CA data/NSDUH State Tables 2016-2017.pdf
2012-2014 CA Rx misuse rate: 4.76, from above doc and Box/2019 OUD CHCF County Estimates/3 Data/NSDUH CA data/CBHSQ 2017 STATE AND SUBSTATE ESTIMATES OF NONMEDICAL USE OF PRESCRIPTION PAIN RELIEVERS.pdf
************************************************/

*Create globals for the percent change in the CA rate from 2012-2014 to 2016-2017
gl perchange = 4.3/4.76

gen RxMisuse_2017 = RxMisuse_2012_2014 * $perchange
label variable RxMisuse_2017 "2017 Rx Misuse, inflated using CA 2016-2016 misuse rate"

/************************************************
Calculate Rx OUD as 11.86% of people who have Rx misuse, from the 2016-2017 NSDUH state tables and specific to CA
This is computed as the OUD rate / the misuse rate (0.51 / 4.3) for CA in the combed 2016-2017 NSDUH.
************************************************/
gl Rx_OUD_misuse = 0.51 / 4.3
gen RxOUD = RxMisuse_2017 * $Rx_OUD_misuse
label variable RxOUD "Rx OUD, 2017"

/************************************************
Calculate all OUD (Rx and heroin) by accounting for the 20.5% of people with OUD who have HUD but not Rx OUD 
from Table 6.44B from the 2017 NSDUH detailed tables, which uses data from the combined 2016 and 2017 NSDUH. 
This is substantially higher than 9.8% reported by Wu et al. that we used in the last round of analysis. 
Their calculation is from the combined 2003-2015 NSDUH.

Divide the Rx OUD rate by (1 - .205), which is multipling by 1 / (1 - .205)
************************************************/
gl heroininfation = 1 / (1 - .205)

gen OUD1 = RxOUD * $heroininfation
label variable OUD1 "NSDUH only OUD rates (Method 1), substate level"


/**********************
OUD estimates 2: NSDUH to Barocas ratio
Barocas MA 2015 OUD rate / MA 2015 NSDUH OUD rate 
We use the same methodology as above to estimate the MA 2015 OUD rate from NSDUH
This inflates our NSDUH estimates by a scalar relative to the Barocas estimates
We use MA 2015 because we believe it to be more similar to CA 2017, because of the influx of fentanyl in MA in later years
**********************/

*MA 2012-2014 Rx misuse: 3.49%
*MA 2015-2016 Rx misuse: 3.90%
*MA 2015-2016 Rx OUD: 0.68%
global MA_RxMisuse_2015 = 3.90
gl MA_Rx_OUD_misuse = 0.68 / 3.90
gl MA_RxOUD = $MA_RxMisuse_2015 * $MA_Rx_OUD_misuse
di $MA_RxOUD

*Use same heroin inflation factor as above because it's a national rate
gl MA_OUD_15 = $MA_RxOUD * $heroininfation
di "MA 2015 NSDUH OUD estimate: $MA_OUD_15"

*Barocas 2015 MA OUD rate: 4.60%
*Barocas scalar = Barocas 2015 MA OUD / NSDUH 2015 MA OUD
gl Barocas_NSDUH_scalar = 4.60 / $MA_OUD_15
di "Barocas scalar: $Barocas_NSDUH_scalar"

*OUD estimates 2, scaling up NSDUH using the Barocas scalar
gen OUD2 = OUD1 * $Barocas_NSDUH_scalar
label variable OUD2 "NSDUH to Barocas ratio OUD rates, substate level"

list substate OUD1 OUD2
summarize OUD1 OUD2

egen OUD = rowmean(OUD1 OUD2)
label variable OUD "Average of 2 methods of OUD rates"

summarize OUD1 OUD2 OUD

drop Substate_Long
export excel using "${output}/OUD substate rates_${today}.xlsx", firstrow(varlabels) replace

save "OUDrates.dta", replace


/*******************************************************
Pull in 2018 CA Overdose Surveillance Dashboard measures
Jaynia Anderson from CDPH sent us 2018 rates before they were posted publicly
*******************************************************/
import excel using "${dashboard}\Urban Institute Data Request - County Indicator Counts 07.31.19_edited variable names.xlsx", cellrange(A3:AG61) firstrow clear
rename County county


/*******************************************************
Import 2018 population counts from the CDC Wonder Bridged-Race Population Estimates
https://wonder.cdc.gov/bridged-race-population.html
*******************************************************/

*All 2018 population
tempfile temp1
save "`temp1'"
import excel using "${pop}\Bridged-Race Population Estimates 2018.xlsx", firstrow cellrange(A1:D60) clear
rename Population pop18
rename County county
keep county pop18
merge 1:1 county using "`temp1'"
drop _m

*Import 2018 county population counts for 12+ years olds
tempfile temp2
save "`temp2'"
import excel using "${pop}\Bridged-Race Population Estimates 2018 12+ Years.xlsx", firstrow cellrange(A1:D60) clear
rename Population pop18_12up
rename County county
keep county pop18_12up
merge 1:1 county using "`temp2'"
drop _m

* Import county population counts of 20-24 year olds 
tempfile temp3
save "`temp3'"
import excel using "${pop}\Bridged-Race Population Estimates 2018 20-24 Year Olds.xlsx", firstrow cellrange(A1:D60) clear
rename Population pop18_20_24
rename County county
keep county pop18_20_24
merge 1:1 county using "`temp3'"
drop _m

gen prop_20_24 = pop18_20_24/pop18


/**** 
Read in LA SPA counts.  
These were sent to us by CDPH since they are not available on the dashboard website. 
*****/

tempfile temp4
save "`temp4'"
	
	import excel using "${dashboard}/LA Crude Rates by SPA/Urban Institute Request - 2018 LA SPA Zip Indicator Counts_9.9.19.xlsx", cellrange(A2:J300) firstrow clear

	rename OpioidPrescriptions1 opioidrx_count
	rename TotalMMEs1 MME_count
	rename OpioidexcludingHeroinOverdo opioidhosp_count
	rename F opioidED_count
	rename AllOpioidrelatedOverdoseDeat death_count
	rename BuprenorphinePrescriptions1 buprx_count
	rename HeroinOverdoseHospitalizations herhosp_count
	rename HeroinOverdoseEmergencyDepart herED_count
	
	
	*Collapse from zip to SPA
	collapse (sum) opioidrx_count MME_count opioidhosp_count opioidED_count death_count buprx_count herhosp_count herED_count, by(SPA)
	rename SPA county
	tostring county, replace
	replace county = "LA SPA 1 and 5" if county == "1"
	replace county = "LA SPA 2" if county == "2"
	replace county = "LA SPA 3" if county == "3"
	replace county = "LA SPA 4" if county == "4"
	replace county = "LA SPA 6" if county == "6"
	replace county = "LA SPA 7" if county == "7"
	replace county = "LA SPA 8" if county == "8"

*Append to main data
append using "`temp4'"


* If there is data for county = "Unknown," drop it. 
drop if county=="Unknown"

*Make sure all possible numeric values are saved as numeric variables if they aren't already
destring, replace

*Compare LA total from dashboard to the sum of the SPA measures by zip
total opioidrx_count MME_count opioidhosp_count opioidED_count death_count buprx_count herhosp_count herED_count if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
total opioidrx_count MME_count opioidhosp_count opioidED_count death_count buprx_count herhosp_count herED_count if county == "Los Angeles"


/*******
Divide LA county population counts by the percent of each SPA that is in LA County
SPA population counts were sent to us by Jaynia from CDPH
Source: American Community Survey, Zip Code Tabulation Area Data, 2017; California Deparment of Finance Population Data, 2018
Saved: Box\2019 OUD CHCF County Estimates\3 Data\CDC Wonder Bridged-Race Population Estimates\2018
*******/

*Merge in SPA population counts
tempfile temp1
save "`temp1'"
	import excel using "${pop}\Urban Institute Request - 2018 Population Counts by SPA_9.9.19_variable names.xlsx", firstrow cellrange(A1:C8) clear
	rename SPA county
	rename Percent SPA_percent
	rename Population SPA_population
merge 1:1 county using "`temp1'"
drop _m

*Save LA populations from Bridged-Race Poplation Estimates
preserve
keep if county == "Los Angeles"
gl pop18_LA = pop18[1]
gl pop18_12up_LA = pop18_12up[1]
gl pop18_20_24_LA = pop18_20_24[1]
restore

/* Check that we captured the correct values
br county pop18_20_24 pop18_12up pop18 if county == "Los Angeles"
*/

*Distribute Bridged Race Population counts between SPAs based on the 2018 SPA percentages from CDPH
replace pop18 = $pop18_LA  * SPA_percent if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace pop18_12up = $pop18_12up_LA  * SPA_percent if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace pop18_20_24 = $pop18_20_24_LA  * SPA_percent if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")


* Calculate crude rates for LA SPAs - used later in the predictions
*There should be 7 changes made for each of the following lines
replace opioidrx_cdrate = opioidrx_count / pop18 * 1000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace MME_cdrate = MME_count / pop18 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

replace opioidhosp_cdrate = opioidhosp_count / pop18 * 100000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace opioidED_cdrate = opioidED_count / pop18 * 100000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

replace death_cdrate = death_count / pop18 * 100000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace buprx_cdrate = buprx_count / pop18 * 1000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

replace herhosp_cdrate = herhosp_count / pop18 * 100000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")
replace herED_cdrate = herED_count / pop18 * 100000 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")

replace prop_20_24 =  pop18_20_24 / pop18 if inlist(county, "LA SPA 1 and 5", "LA SPA 2", "LA SPA 3", "LA SPA 4", "LA SPA 6", "LA SPA 7", "LA SPA 8")


*Create rates for all opioid hospitalizations and ED visits
gen allhosp_count = opioidhosp_count + herhosp_count
gen allED_count = opioidED_count + herED_count

gen allhosp_cdrate = allhosp_count / pop18 * 100000
gen allED_cdrate = allED_count / pop18 * 100000


* Look at the difference between the population they used to calcualte rates and the Bridged-Estimates populations
/*
gen rx_testpop = rx_count / rx_cdrate * 1000
gen rx_popdif = rx_testpop - pop16
gen rx_popperc = rx_popdif / pop16 * 100

gen hosp_testpop = hosp_count / hosp_cdrate * 100000
gen hosp_popdif = hosp_testpop - pop16
gen hosp_popperc = hosp_popdif / pop16 * 100

gen ED_testpop = ED_count / ED_cdrate * 100000
gen ED_popdif = ED_testpop - pop15
gen ED_popperc = ED_popdif / pop15 * 100
*/

*Add in Substate groupings
gen substate=" " 
replace substate="Region 1R" if inlist(county, "Butte", "Colusa", "Del Norte", "Glenn", "Humboldt", "Lake", "Lassen", "Mendocino", "Modoc") ///
	| inlist(county, "Plumas", "Shasta", "Sierra", "Siskiyou", "Tehama", "Trinity")
replace substate="Region 2R" if inlist(county, "El Dorado", "Nevada", "Placer", "Sutter", "Yolo", "Yuba")
replace substate="Region 3R" if county=="Sacramento"
replace substate="Region 4R" if inlist(county, "Marin", "Napa", "Solano", "Sonoma")
replace substate="Region 5R" if county=="San Francisco"
replace substate="Region 6" if county=="Santa Clara"
replace substate="Region 7R" if county=="Contra Costa"
replace substate="Region 8R" if county=="Alameda"
replace substate="Region 9R" if county=="San Mateo"
replace substate="Region 10" if inlist(county, "Santa Barbara", "Ventura")
replace substate="Region 11" if county=="Los Angeles" /* LA is further split into 7 service planning areas (SPAs) defind by census tracts (from the 2010 census) */
replace substate="Region 12R" if inlist(county, "Alpine", "Amador", "Calaveras", "Mono", "San Joaquin", "Tuolumne")
replace substate="Regions 13 and 19R" if inlist(county, "Imperial", "Riverside")
replace substate="Region 14" if county=="Orange"
replace substate="Region 15R" if county=="Fresno"
replace substate="Region 16R" if county=="San Diego"
replace substate="Region 17R" if inlist(county, "Inyo", "Kern", "Kings", "Tulare")
replace substate="Region 18R" if county=="San Bernardino"
replace substate="Region 20R" if inlist(county, "Madera", "Mariposa","Merced", "Stanislaus")
replace substate="Region 21R" if inlist(county, "Monterey", "San Benito", "San Luis Obispo", "Santa Cruz")
replace substate="California" if county=="California" /* Keep to look at totals */

replace substate="LA SPA 1 and 5" if county=="LA SPA 1 and 5"
replace substate="LA SPA 2" if county=="LA SPA 2"
replace substate="LA SPA 3" if county=="LA SPA 3"
replace substate="LA SPA 4" if county=="LA SPA 4"
replace substate="LA SPA 6" if county=="LA SPA 6"
replace substate="LA SPA 7" if county=="LA SPA 7"
replace substate="LA SPA 8" if county=="LA SPA 8"


* Save dataset at the county level
save "countydata_SPAs.dta", replace


/**************************************************
Merge in OUD rates and save to substate level
**************************************************/

use "countydata_SPAs.dta", clear

collapse (sum) pop18 pop18_12up pop18_20_24 opioidrx_count MME_count opioidhosp_count opioidED_count death_count buprx_count herhosp_count herED_count allhosp_count allED_count, by(substate)
sort substate

*Calculate crude rates by substate
*Keep rates at per 1,000 or per 100,000 as they are for counties
gen opioidrx_subst_rt = opioidrx_count / pop18 * 1000
gen MME_subst_rt = MME_count / pop18
gen opioidhosp_subst_rt = opioidhosp_count / pop18 * 100000
gen opioidED_subst_rt = opioidED_count / pop18 * 100000
gen death_subst_rt = death_count / pop18 * 100000
gen buprx_subst_rt = buprx_count / pop18 * 1000
gen herhosp_subst_rt = herhosp_count / pop18 * 100000
gen herED_subst_rt = herED_count / pop18 * 100000

gen allhosp_subst_rt = allhosp_count / pop18 * 100000
gen allED_subst_rt = allED_count / pop18 * 100000

*Generage proportion of population in different age groups for 2018
gen prop_20_24 = pop18_20_24 / pop18

*Merge in substate OUD rates
merge 1:1 substate using "OUDrates.dta"
drop _m
drop if substate == "West"

*Drop Region 11, which is the Los Angles total, so that we don't double count those people
drop if substate == "Region 11"

*Create variables for OUD counts 
gen OUD1count = OUD1 / 100 * pop18_12up
label variable OUD1count "NSDUH only OUD counts (Method 1)"

gen OUD2count = OUD2 / 100 * pop18_12up
label variable OUD2count "NSDUH to Barocas ratio OUD counts, substate level"

save "substatedata_SPAs.dta", replace




/*************************************
FINAL MODEL DECISION

We ran many models in the section of code called "TRY MODELS TO DETERMINE WHICH FINAL MODEL WE WILL USE"
below, and decided on a final model which we use here.
*************************************/

*log using "${log}\Final Model_revise.log", replace

use "substatedata_SPAs.dta", clear

* Drop CA total. Drop LA total (region 11) since we use individual LA SPAs.
drop if inlist(substate, "California", "Region 11") 

*Create weights based on 2018 population
egen poptot18_12up = total(pop18_12up)
gen weight18_12up = pop18_12up / poptot18_12up

*We want the independent variables to have the same name in the substate and county datasets. Rename the two independent variables we use in the model
* to have the same name as the variable in the county dataest
rename opioidrx_subst_rt opioidrx_cdrate
rename buprx_subst_rt buprx_cdrate
rename allED_subst_rt allED_cdrate
rename MME_subst_rt MME_cdrate
rename opioidhosp_subst_rt opioidhosp_cdrate
list substate MME_cdrate opioidhosp_cdrate prop_20_24

*Run regression (10-3-19 R-squared = 0.5413)
regress OUD  MME_cdrate opioidhosp_cdrate prop_20_24
*log close

estimates store model
predict pred1
list substate pred1

*Predict OUD rates on counties using regression output
use "countydata_SPAs.dta", clear

*Drop LA total but keep CA total
drop if inlist(substate, "Region 11") 

predict OUD_countyperc
label variable OUD_countyperc "OUD County Percent from model predictions"
list county substate OUD_countyperc


/***************************************************************
* For substates with more than 1 county, calculate the percent of OUD counts for each county within the substate
***************************************************************/

sort substate county

*Calculate estimated counts of OUD
gen OUD_modelcount = (OUD_countyperc / 100) * pop18_12up /*cross multipication to get counts from the predicted % and pop*/
label variable OUD_modelcount "OUD estimates from the model, per county"

*Sum total counts per substate
egen OUD_total_count = total(OUD_modelcount), by(substate)
label variable OUD_total_count "Substate OUD estimates from the model (sum of counties), 12+"

*Calculate percent of OUD counts per county by substate. Should be 1 if there is only one region per substate
gen OUD_substate_perc = OUD_modelcount/OUD_total_count
label variable OUD_substate_perc "Percent of OUD counts per county by substate"
sort substate
list substate county OUD_substate_perc

*Check that they all add up to 1. test = 0 is for CA total
egen test=total(OUD_substate_perc), by(substate)
tab test
drop test

save "county_intermediate_SPAs.dta", replace


*Using original substate OUD estimate, distribute couts of people with OUD across county within those substates
use "substatedata_SPAs.dta", clear

* Drop LA total (region 11) and keep LA substates
drop if inlist(substate,"West") | substate=="Region 11"
keep substate OUD OUD1 OUD1count OUD2 OUD2count pop18_12up
rename pop18_12up pop18_12up_substate
merge 1:m substate using "county_intermediate_SPAs.dta"
drop _m

*Rename OUD to indicate that it is the OUD substate rates
rename OUD OUD_substate

*Check that substate populations match county populations when only one county per substate
sort substate county
list substate county OUD_substate pop18_12up_substate pop18_12up

*Calculate OUD counts per substate using original OUD substate rate and total substate 12+ pop
gen OUD_subs_count = (OUD_substate / 100) * pop18_12up_substate
label variable OUD_subs_count "OUD substate count"
list substate county OUD_substate pop18_12up_substate OUD_subs_count

*Calculate county counts by multiplying the substate total counts by the percent of OUD that the county represents in each substate. 
*If there is only 1 county in the substate, the OUD count should be the same
gen newOUDcount = ceil(OUD_subs_count * OUD_substate_perc)
label variable newOUDcount "OUD county count (avg of 2 methods) after model, 12+"
list substate county OUD_substate OUD_subs_count newOUDcount

*Use this new distributed county to replace the rates we got from the model
gen newOUDrate = newOUDcount / pop18_12up * 100
label variable newOUDrate "OUD county percents (avg of 2 methods) after model, 12+"
list substate county OUD_substate newOUDrate 
summarize OUD_substate newOUDrate 

*Add in Calfiornia totals
replace newOUDcount = . if county == "California"
total newOUDcount
mat totOUD = e(b)
gl totOUD = totOUD[1,1]
replace newOUDcount = $totOUD if county == "California"
replace newOUDrate = newOUDcount / pop18_12up * 100 if county == "California"

list county substate newOUDcount newOUDrate

sort substate county
list county substate OUD_county OUD_substate_perc OUD_subs_count 

*Add opioid misuse back in. 18.2% of people with opioid misuse (Rx or heroin) have OUD (Rx or heroin)
* From:(2017 NSDUH detailed tables, Table 6.43B)
gen OUDmisuse_count = newOUDcount / .182
gen OUDmisuse_rate = OUDmisuse_count / pop18_12up * 100

label variable OUDmisuse_count "OUD misuse count, all opioids"
label variable OUDmisuse_rate "OUD misuse rate, all opioids"

*Print OUD counts and percents 
sort county
export excel county substate OUD1 OUD2 newOUDrate newOUDcount death_count death_cdrate using "${output}/OUD counts and rates_${today}.xlsx", firstrow(varlabels) replace

*export excel county substate OUD_county OUD_substate_perc OUD_subs_count  using "${output}\OUD County Counts.xlsx", replace firstrow(varlabels)

*Keep final variables that we will report
keep substate county pop18_12up pop18 SPA_percent opioidrx_cdrate opioidrx_count buprx_cdrate buprx_count MME_cdrate MME_count ///
	opioidhosp_cdrate opioidhosp_count opioidED_cdrate opioidED_count death_cdrate death_count herhosp_cdrate ///
	herhosp_count herED_cdrate herED_count allhosp_count allED_count allhosp_cdrate allED_cdrate ///
	newOUDcount newOUDrate OUDmisuse_count OUDmisuse_rate OUD1 OUD1count OUD2 OUD2count

	
order substate county pop18_12up pop18 opioidrx_cdrate opioidrx_count buprx_cdrate buprx_count MME_cdrate MME_count ///
	opioidhosp_cdrate opioidhosp_count opioidED_cdrate opioidED_count death_cdrate death_count herhosp_cdrate ///
	herhosp_count herED_cdrate herED_count allhosp_count allED_count allhosp_cdrate allED_cdrate ///
	newOUDcount newOUDrate OUDmisuse_count OUDmisuse_rate OUD1 OUD1count OUD2 OUD2count
	
label variable substate "Substate"
label variable county "County"

*Add in other variable labels
label variable opioidrx_cdrate "Opioid Rx Crude Rate"
label variable opioidrx_count "Opioid Rx Count"
label variable MME_cdrate "MME Crude Rate"
label variable MME_count "MME Count"
label variable opioidhosp_cdrate "Opioid (not incl heroin) Hospitalizations Crude Rate"
label variable opioidhosp_count "Opioid (not incl heroin) Hospitalizations Count"
label variable opioidED_cdrate "Opioid (not incl heroin) ED Crude Rate"
label variable opioidED_count "Opioid (not incl heroin) ED Count"
label variable death_cdrate "Deaths Crude Rate"
label variable death_count "Deaths Count"
label variable buprx_cdrate "Bup Rx Crude Rate"
label variable buprx_count "Bup Rx Count"
label variable herhosp_cdrate "Heroin Hospitalizations Crude Rate"
label variable herhosp_count "Heroin Hospitalizations Count"
label variable herED_cdrate "Heroin ED Crude Rate"
label variable herED_count "Heroin ED Count"
label variable allhosp_count "All Opioid Hospitalizations Count"
label variable allhosp_cdrate "All Opioid Hospitalizations Crude Rate"
label variable allED_count "All Opioid ED Count"
label variable allED_cdrate "All Opioid ED Crude Rate"
label variable SPA_percent "SPA population percent"

save "OUDcounts_finalvars.dta", replace


log close












/***************************************************************
TRY MODELS TO DETERMINE WHICH FINAL MODEL WE WILL USE

REGRESS prevalence of opioid use (% with OUD) on 5 independent variables:
	- opioid prescriptions, excluding bup, per 1,000, 2018
	- MME per resident (excluding bup), 2018
	- opioid overdose hospitilizations, per 100,000, 2018
	- opioid overdose ED visits, per 100,000, 2018
	- opioid overdose deaths, per 100,000, 2018
	
Final model from last round: 
	regress OUD  bup_cdrate ED_cdrate prop_20_24  [weight=weight16]
	R squared 0.4046
****************************************************************/

log using "${log}/Regression Models Output_${today}.log", replace


clear
use "substatedata_SPAs.dta"

* Drop CA total. Drop LA total (region 11) since we use individual LA SPAs.
drop if inlist(substate, "California", "Region 11") 

*Create weights based on 2018 population
egen poptot18 = total(pop18)
gen weight18 = pop18 / poptot18

egen poptot18_12up = total(pop18_12up)
gen weight18_12up = pop18_12up / poptot18_12up

/*******
Correlation
********/

correlate OUD opioidrx_subst_rt MME_subst_rt opioidhosp_subst_rt opioidED_subst_rt death_subst_rt buprx_subst_rt allhosp_subst_rt allED_subst_rt prop_20_24
 
/*********** 
A few models, with and without weights
***********/

regress OUD  buprx_subst_rt opioidED_subst_rt prop_20_24
regress OUD  buprx_subst_rt opioidED_subst_rt prop_20_24 [weight=weight18]

regress OUD  buprx_subst_rt opioidhosp_subst_rt prop_20_24
regress OUD  buprx_subst_rt opioidhosp_subst_rt prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt opioidhosp_subst_rt prop_20_24
regress OUD  MME_subst_rt opioidhosp_subst_rt prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt opioidED_subst_rt prop_20_24
regress OUD  MME_subst_rt opioidED_subst_rt prop_20_24 [weight=weight18]

regress OUD  opioidrx_subst_rt opioidED_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt opioidED_subst_rt prop_20_24 [weight=weight18]

regress OUD  opioidrx_subst_rt opioidhosp_subst_rt  prop_20_24
regress OUD  opioidrx_subst_rt opioidhosp_subst_rt  prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt buprx_subst_rt  prop_20_24 
regress OUD  MME_subst_rt buprx_subst_rt  prop_20_24 [weight=weight18]

regress OUD  opioidrx_subst_rt allED_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt allED_subst_rt prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt allED_subst_rt prop_20_24
regress OUD  MME_subst_rt allED_subst_rt prop_20_24 [weight=weight18]

regress OUD  opioidrx_subst_rt allhosp_subst_rt  prop_20_24
regress OUD  opioidrx_subst_rt allhosp_subst_rt  prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt buprx_subst_rt allED_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt buprx_subst_rt allED_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt MME_subst_rt allED_subst_rt prop_20_24

regress OUD  MME_subst_rt buprx_subst_rt allED_subst_rt prop_20_24 [weight=weight18]
regress OUD  opioidrx_subst_rt buprx_subst_rt allED_subst_rt prop_20_24 [weight=weight18]
regress OUD  opioidrx_subst_rt MME_subst_rt allED_subst_rt prop_20_24 [weight=weight18]

regress OUD  MME_subst_rt buprx_subst_rt allED_subst_rt prop_20_24 [weight=weight18_12up]
regress OUD  opioidrx_subst_rt buprx_subst_rt allED_subst_rt prop_20_24 [weight=weight18_12up]
regress OUD  opioidrx_subst_rt MME_subst_rt allED_subst_rt prop_20_24 [weight=weight18_12up]

regress OUD  MME_subst_rt buprx_subst_rt allhosp_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt buprx_subst_rt allhosp_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt MME_subst_rt allhosp_subst_rt prop_20_24


/*************** 
Try one variable at a time with age
****************/
regress OUD  buprx_subst_rt prop_20_24
regress OUD  opioidrx_subst_rt prop_20_24
regress OUD  MME_subst_rt prop_20_24
regress OUD  opioidhosp_subst_rt prop_20_24
regress OUD  opioidED_subst_rt prop_20_24
regress OUD  death_subst_rt prop_20_24

regress OUD  buprx_subst_rt prop_20_24 [weight=weight18]
regress OUD  opioidrx_subst_rt prop_20_24 [weight=weight18]
regress OUD  MME_subst_rt prop_20_24 [weight=weight18]
regress OUD  opioidhosp_subst_rt prop_20_24 [weight=weight18]
regress OUD  opioidED_subst_rt prop_20_24 [weight=weight18]
regress OUD  death_subst_rt prop_20_24 [weight=weight18]



log close




/* 09-16-19 models (methods 1 and 4) and R-squared
regress OUD  opioidrx_subst_rt allED_subst_rt prop_20_24
0.7956

. regress OUD  MME_subst_rt allED_subst_rt prop_20_24
0.7926

. regress OUD  MME_subst_rt buprx_subst_rt allED_subst_rt prop_20_24
0.8068

. regress OUD  opioidrx_subst_rt buprx_subst_rt allED_subst_rt prop_20_24
0.8100

. regress OUD  opioidrx_subst_rt MME_subst_rt allED_subst_rt prop_20_24
0.8020

*/



/* 10-03-19 models (methods 1 and 2) and R-squared
OUD  MME_subst_rt opioidhosp_subst_rt prop_20_24, 0.5413


*/




