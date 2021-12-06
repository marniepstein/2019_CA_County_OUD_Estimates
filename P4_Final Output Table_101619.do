/**********************************************************
Name: Final Output Table
Project: CA County Estimates of OUD	
Purpose: OTP Counts of treatment centers and methadone/bup patients
Author: Marni Epstein
Date: September 2017

Note: This version uses 2 estimates of treatment capacity. Out of county prescribers always treat half that of in-county 30-waivered prescribers
	1.	All prescribers treat 16 (average unique in-county patients per bupe prescriber). We assume out of county prescribers treat half that, 8
	3.	30 waivered prescribers treat 30 and 100 and 275 prescribers treat at half capacity. Out of county prescribers treat 15

***********************************************************/


*Enter user (computer name)
global user = "MEpstein"

*Enter today's date to create unique log
global today=102319

*Set directory and globals
cd "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Datasets"

global output "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Output"
global log "D:\Users\MEpstein\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Logs"
global dashboard "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\CA Opioid Overdose Surveillance Dashboard\2018 Crude Rates"
global lastround "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\Analysis\Datasets"


/*********************************************************************/

log using "${log}/P4_Final_Output_Table_${today}.log", replace

*Use OUD dataset from P1
use "OUDcounts_finalvars.dta", clear

* Add in OTP data from P2
* Only 35 counties have OTPs, which is why there will be a lot of unmatched obs from master
merge 1:1 county using "OTPcounts.dta"
drop _m

*Add in waivered prescriber info. The _m == 2 is LA county
merge 1:1 county using "prescriber_DEA_numbers.dta"
drop _m



*Drop if county is unknown and drop LA county since we only use the SPAs from here on
drop if inlist(county, "Unknown", "Los Angeles")

*Replace missings with 0s. Sierra has no CURES or prescriber data so it has a lot of missing
replace NTISwaiver30 = 0 if NTISwaiver30 == .
replace NTISwaiver100 = 0 if NTISwaiver100 == .
replace NTISwaiver275 = 0 if NTISwaiver275 == .
replace bupwaivproviders = 0 if bupwaivproviders == .

replace bupprx_byprxcounty = 0 if bupprx_byprxcounty == .
replace allprx_byprxcounty = 0 if allprx_byprxcounty == .
replace bupprx_bypatcounty = 0 if bupprx_bypatcounty == .
replace allprx_bypatcounty = 0 if allprx_bypatcounty == .
replace treatcap3bup = 0 if treatcap3==.
replace OTPcount = 0 if OTPcount == .
replace Totalslots =0 if Totalslots == .
replace bupotp_patients = 0 if bupotp_patients == .
replace methadone_patients = 0 if methadone_patients == .

/***********************************
*Add in CA totals
Include upper bound treatment capacity. Could calculate it using total prescribers but it's slightly off the sum due to rounding
***********************************/
*browse if county == "California"

foreach var in opioidrx_count buprx_count MME_count opioidhosp_count opioidED_count death_count herhosp_count herED_count ///
allhosp_count allED_count OTPcount Totalslots methadone_patients bupotp_patients ///
 NTISwaiver30 NTISwaiver100 NTISwaiver275 prescriber bupwaivproviders ///
 totbuppat_bypatcty buppatincty_bypatcty buppatoutcty_bypatcty buppatonlyincty_bypatcty buppatonlyoutcty_bypatcty buppatinandout_bypatcty treatcap3 {

	*Make sure the the value is missing for CA
	replace `var' = . if county == "California"
	total `var'	
	mat mat`var' = e(b)
	gl CA_`var' = mat`var'[1,1]
	di "Variable = `var', value = ${CA_`var'}"
	
	replace `var' = ${CA_`var'} if county == "California"
}

*Calculate rates for totals
replace opioidrx_cdrate = opioidrx_count / pop18 * 1000 if county == "California"
replace MME_cdrate = MME_count / pop18 if county == "California"
replace opioidhosp_cdrate = opioidhosp_count / pop18 * 100000 if county == "California"
replace opioidED_cdrate = opioidED_count / pop18 * 100000 if county == "California"
replace death_cdrate = death_count / pop18 * 100000 if county == "California"
replace buprx_cdrate = buprx_count / pop18 * 1000 if county == "California"
replace herhosp_cdrate = herhosp_count / pop18 * 100000 if county == "California"
replace herED_cdrate = herED_count / pop18 * 100000 if county == "California"
replace allhosp_cdrate = allhosp_count / pop18 * 100000 if county == "California"
replace allED_cdrate = allED_count / pop18 * 100000 if county == "California"


*Re-calculate rates shown in the fact sheet to use the demonimator of 12+
replace death_cdrate = death_count / pop18_12up * 100000
replace buprx_cdrate = buprx_count / pop18_12up * 1000



/******************************************************************************
Treatment capacity and gap using current number of bupe patients
******************************************************************************/

*Percent currenty receiving treatment and teatment gap based on number of bupe patients

*All bupe patients in the county
gen curtreat_all = totbuppat_bypatcty + methadone_patients + bupotp_patients
label variable curtreat_all "Current treatment estimate: all bupe patients by pat county + OTP patients"

gen curtreat_all_perc = curtreat_all / newOUDcount * 100
label variable curtreat_all_perc "Percent with OUD receiving treatment, bupe in or out of county and methadone"

gen curtreatgap_all = newOUDcount - curtreat_all
replace curtreatgap_all = 0 if curtreatgap_all < 0
label variable curtreatgap_all "Number with OUD not receiving any treatment"

*Only bupe patients receiving in-county bupe treatment
gen curtreat_incty = buppatincty_bypatcty + methadone_patients + bupotp_patients
label variable curtreat_incty "Number of bupe patients receiving treatment in county, by patient county + methadone patients"

gen curtreat_incty_perc = curtreat_incty / newOUDcount * 100
label variable curtreat_incty_perc "Percent with OUD receiving treatment, bupe in county and methadone"

gen curtreatgap_incty = newOUDcount - curtreat_incty
replace curtreatgap_incty = 0 if curtreatgap_incty < 0
label variable curtreatgap_incty "Number with OUD not receiving in county treatment"


/******************************************************************************
Treatment capacity and gap using number of providers and total slots
******************************************************************************/

*Add total methadone slots and patients getting bupe at OTPs and patients getting bupe out of county 
gen treatcap3 = treatcap3bup + Totalslots + bupotp_patients + buppatonlyoutcty_bypatcty
label variable treatcap3 "Treatment Capacity, 30 waiver treat 30, 100 and 275 treat half capacity + OTP slots + bupe get tx OOC"

*Treatment gap if everyone got treatment based on number of prescribers

*Calculate the treatment gap, using different treatment capacity estimates
*Subtract patients getting treatment out of county from the treatment gap since they already are getting treatment
*Note, use buppatonlyoutcty_bypatcty which is patients who only get treatment out of county
gen treatgap_cap3 = newOUDcount - treatcap3
replace treatgap_cap3=0 if treatgap_cap3<0
label variable treatgap_cap3 "Treatment gap, 30 waiver treat 30, 100 and 275 treat half capacity"

*Upper bound Treatment gap for CA total differes from the sum of counties because 5 counties have a treatment gap of under 0.
*Use the sum of the counties so that totals match up
foreach var in curtreatgap_all treatgap_cap3 {
	*Make sure the the value is missing for CA
	replace `var' = . if county == "California"
	total `var'	
	mat mat`var' = e(b)
	gl CA_`var' = mat`var'[1,1]
	di "Variable = `var', value = ${CA_`var'}"
	
	replace `var' = ${CA_`var'} if county == "California"
}

*Calculate how many new 30-waiver providers would be needed to cover the gap. 
gen newprov_3 = ceil(treatgap_cap3 / 30)
replace newprov_3 = 0 if newprov_3 < 0
label variable newprov_3 "New 30-waiver prx needed, new treat 30 each"

list county bupwaivproviders newprov_*

gen newprov_curtreat = ceil(curtreatgap_all / 16)
label variable newprov_curtreat "New 30-waiver prx needed based on current patients receiving treatment, new treat 16 each"


list county newprov_curtreat newprov_3


/****************************************
Cap the number of new prescribers at the number of current bup prescribers so that counties never more than double their number of prescribers
Use allproviders_adj as the cap, which is the total # prescribers from NTIS, adjusted for CURES
****************************************/
gen cap = bupwaivproviders
list county NTISwaiver* bupwaivproviders prescriber if bupwaivproviders==. | bupwaivproviders==0

*If there are no bup prescribers in the county (Alpine), we use 20% of all prescribers as the cap
replace cap = round(.2*prescriber, 1) if bupwaivproviders==0
list county cap bupwaivproviders prescriber if bupwaivproviders==0

label variable cap "Cap for # new prx to double num of bup prx"

gen newprov_capped3 = newprov_3
replace newprov_capped3 = cap if newprov_3 > cap

gen newprov_cappedcurtreat = newprov_curtreat
replace newprov_cappedcurtreat = cap if newprov_curtreat > cap

label variable newprov_capped3 "New 30-prx, capped, new treat 30 each and current 30/half capacity"
label variable newprov_cappedcurtreat "New 30-prx, capped, treat 16 each, based on current receiving treatment"

list county newprov_cappedcurtreat newprov_capped3

* Calculate the percent that the cap would fill the treatment gap, to report when we report the cap instead of the true number of new providers needed
* When the new providers is the lower than the cap, this should be 100%. 
* When the new prov is replaced with the cap, this will be under 100%.
* When there is 0 treatment gap, the percent of the treatment gap filled will be missing
gen perc_gapfilled3 = ((30*newprov_capped3) / treatgap_cap3) * 100
gen perc_gapfilled_curtreat = ((16*newprov_cappedcurtreat) / curtreatgap_all) * 100

*if the percent_gapfilled is over 100, it's because of rounding. replace all values over 100 with 100
replace perc_gapfilled3 = 100 if perc_gapfilled3 > 100
replace perc_gapfilled_curtreat = 100 if perc_gapfilled_curtreat > 100

label variable perc_gapfilled3 "% of the tx gap filled, new prov treat 30 each and current treat 30/half capacity"
label variable perc_gapfilled_curtreat "% of the tx gap filled, based on current receiving treatment, new and current prov treat 16 each"

list county cap newprov_cappedcurtreat perc_gapfilled_curtreat newprov_capped3 perc_gapfilled3 

*Create variable to indicate if the new provider recommendations are both above the cap, both below cap, or just the upper bound is above the cap. 
* This will be used in the R Markdown template

gen cap_indicator=.
replace cap_indicator=1 if newprov_curtreat <= cap & newprov_3 <= cap /* both are less than or equal to cap */
replace cap_indicator=2 if newprov_curtreat > cap & newprov_3 <= cap /* Just upper bound is greater than cap */
replace cap_indicator=3 if newprov_curtreat > cap & newprov_3 > cap /* Both are greater than cap */

label variable cap_indicator "Cap indicator - neither, upper bound, or both bounds capped"

tab cap_indicator, m
list county cap_indicator newprov_cappedcurtreat newprov_capped3 newprov_curtreat newprov_3

*Sum the number of uncapped and capped prescribers for CA overall
foreach var in newprov_3 newprov_curtreat newprov_capped3 newprov_cappedcurtreat {
	*Make sure the the value is missing for CA
	replace `var' = . if county == "California"
	total `var'	
	mat mat`var' = e(b)
	gl CA_`var' = mat`var'[1,1]
	di "Variable = `var', value = ${CA_`var'}"
	
	replace `var' = ${CA_`var'} if county == "California"
}

*Calculate the percent of the CA overall treatment gap that these new prescribers fill
replace perc_gapfilled3 = ((30*newprov_capped3) / treatgap_cap3) * 100 if county == "California"
replace perc_gapfilled_curtreat = ((16*newprov_cappedcurtreat) / curtreatgap_all) * 100 if county == "California"


* Print new provider numbers and cap
*export excel county newprov_19perc_1 newprov_19perc_3 newprov_19perc_4 cap allproviders_adj bupprx_byprxcounty bupprx_bypatcounty allprx_byprxcounty allprx_bypatcounty ///
*using "${output}\Second Run with LA SPAs\New Providers Needed and Cap.xlsx", replace firstrow(varlabels)

*Calculate percent of current prescribers who have a DATA waiver
* USE DEA DATA
gen perc_waiver = (bupwaivproviders / prescriber) * 100
label variable perc_waiver "Percent of current prescribers who have a DATA waiver, NTIS DEA"


*Add in OTP and methadone slots rates
gen double OTP_rate = OTPcount / pop18_12up * 100000
gen double Totalslots_rate = Totalslots / pop18_12up * 100000

*Replace variables that measure people rounded to the top integer
foreach var of varlist newOUDcount treatcap3 treatgap_cap3 Totalslots {
	replace `var'=ceil(`var')
}

*Round variables
*Take age adjusted variables out since we're not using them for now
* rx_ageadj bup_ageadj MME_ageadj hosp_ageadj her_hosp_ageadj ED_ageadj her_ED_ageadj death_ageadj
replace MME_count=round(MME_count,1)
foreach var of varlist opioidrx_cdrate buprx_cdrate MME_cdrate opioidhosp_cdrate herhosp_cdrate ///
	opioidED_cdrate herED_cdrate death_cdrate OTP_rate Totalslots_rate {
		replace `var'=round(`var',.1)
}

/*************************
Add in workforce estimates using the number of poeple with OUD (newOUDcount)
Calculations are from the Opioid Workforce Estimation tool: Box\2019 OUD CHCF County Estimates\2 Lit\ASAM workforce\Opioid Workforce Tool.xlsx
This is just for estimated MDs
*************************/
gen txneed_lvl2 = newOUDcount * .30
gen txneed_lvl3 = newOUDcount * .15
gen txneed_lvl4 = newOUDcount * .20

label variable txneed_lvl2 "ASAM Level 2 treatment need, opioid workforce tool" 
label variable txneed_lvl3 "ASAM Level 3 treatment need, opioid workforce tool" 
label variable txneed_lvl4 "ASAM Level 4 treatment need, opioid workforce tool" 

gen wrkforce_lvl2 = round(txneed_lvl2 / 300, 0)
gen wrkforce_lvl3 = round(txneed_lvl3 / 30, 0)
gen wrkforce_lvl4 = round(txneed_lvl4 / 20, 0)

label variable wrkforce_lvl2 "ASAM Level 2 MDs needed, opioid workforce tool"
label variable wrkforce_lvl3 "ASAM Level 3 MDs needed, opioid workforce tool"
label variable wrkforce_lvl4 "ASAM Level 4 MDs needed, opioid workforce tool"

*Export workforce numbers
export excel county wrkforce_lvl2 wrkforce_lvl3 wrkforce_lvl4 using "${output}/Workforce Provider Numbers.xlsx", replace firstrow(varlabels)


*Add in other variable labels
label variable OTPcount "OTP Count per county"
label variable OTP_rate "OTPs per 100,000 12+"
label variable Totalslots_rate "OTP Slots per 100,000 12+"
label variable Totalslots "OTP slots per county"
label variable pop18_12up "2018 population 12+"
label variable pop18 "2018 population"

label variable county "County"
rename prescriber totalprescribers

order county substate  

*Merge in prescriber variables from last round. Just use DEA, not inflated for CURES, prescriber numbers
tempfile temp
save "`temp'"
use "${lastround}/finaldataset.dta", clear
rename NTISwaiver30 waiver30_2018
rename NTISwaiver100 waiver100_2018
rename NTISwaiver275 waiver275_2018
keep county waiver30_2018 waiver100_2018 waiver275_2018
merge 1:1 county using "`temp'"
drop _m

*Sum the number of prescibers for CA overall
foreach var in waiver30_2018 waiver100_2018 waiver275_2018 {
	*Make sure the the value is missing for CA
	replace `var' = . if county == "California"
	total `var'	
	mat mat`var' = e(b)
	gl CA_`var' = mat`var'[1,1]
	di "Variable = `var', value = ${CA_`var'}"
	
	replace `var' = ${CA_`var'} if county == "California"
}


*Calculate how many new prescribers there are since the last round (Feb 2018 prescriber data_
gen newwaiver30 = NTISwaiver30 - waiver30_2018
gen newwaiver100 = NTISwaiver100 - waiver100_2018
gen newwaiver275 = NTISwaiver275 - waiver275_2018

label variable waiver30_2018 "30-waivered prescribres, Feb 2018, NTIS DEA"
label variable waiver100_2018 "100-waivered prescribres, Feb 2018, NTIS DEA"
label variable waiver275_2018 "275-waivered prescribres, Feb 2018, NTIS DEA"
label variable newwaiver30 "New 30-waivered prescribers since Feb 2018"
label variable newwaiver100 "New 100-waivered prescribers since Feb 2018"
label variable newwaiver275 "New 275-waivered prescribers since Feb 2018"


*Drop variables used to distribute LA totals
drop LA_bupe_prescribers LA_bupe_prescribers_perc SPA_percent


* Order variables
order county substate pop18 pop18_12up opioidrx_cdrate opioidrx_count buprx_cdrate buprx_count ///
MME_cdrate MME_count opioidhosp_cdrate opioidhosp_count opioidED_cdrate opioidED_count death_cdrate death_count ///
herhosp_cdrate herhosp_count herED_cdrate herED_count allhosp_count allED_count allhosp_cdrate allED_cdrate ///
OUD1 OUD1count OUD2 OUD2count newOUDcount newOUDrate OUDmisuse_count OUDmisuse_rate  ///
OTPcount OTP_rate Totalslots Totalslots_rate methadone_patients bupotp_patients ///
avg_buppat_perprx tot_buppat_byprxcounty avg_buppat_perprx_incounty tot_buppat_byprxcounty_incounty avg_buppat_perprx_outcounty tot_buppat_byprxcounty_outcounty ///
totbuppat_bypatcty buppatincty_bypatcty buppatoutcty_bypatcty buppatonlyincty_bypatcty buppatonlyoutcty_bypatcty buppatinandout_bypatcty ///
bupprx_byprxcounty allprx_byprxcounty bupprx_bypatcounty allprx_bypatcounty NTISwaiver30 NTISwaiver100 NTISwaiver275 ///
totalprescribers prov_outofcounty NTISwaiver30 NTISwaiver100 NTISwaiver275 bupwaivproviders perc_waiver ///
curtreat_all curtreat_all_perc curtreatgap_all curtreat_incty curtreat_incty_perc curtreatgap_incty ///
treatcap3bup treatcap3 treatgap_cap3 newprov_curtreat newprov_3 cap cap_indicator ///
newprov_cappedcurtreat newprov_capped3 perc_gapfilled_curtreat perc_gapfilled3 /// 
waiver30_2018 waiver100_2018 waiver275_2018 newwaiver30 newwaiver100 newwaiver275 ///
txneed_lvl2 txneed_lvl3 txneed_lvl4 wrkforce_lvl2 wrkforce_lvl3 wrkforce_lvl4


*export excel using "${output}\Second Run with LA SPAs\All final variables - labels.xlsx", replace firstrow(varlabels)
export excel using "${output}/Final Output.xlsx", replace firstrow(varlabels)
export delimited using "${output}/Final Output.csv", replace 

save "final.dta", replace

*Export main numbers to check over
preserve

*
keep county substate OUD1 OUD2 death_count newOUDrate newOUDcount ///
	NTISwaiver30 NTISwaiver100 NTISwaiver275 bupwaivproviders prov_outofcounty totalprescribers perc_waiver totbuppat_bypatcty buppatincty_bypatcty methadone_patients Totalslots bupotp_patients ///
	curtreat_all curtreat_all_perc treatcap3 curtreatgap_all treatgap_cap3 ///
	newprov_curtreat newprov_3 cap newprov_cappedcurtreat newprov_capped3 perc_gapfilled_curtreat perc_gapfilled3

order county substate OUD1 OUD2 death_count newOUDrate newOUDcount ///
	NTISwaiver30 NTISwaiver100 NTISwaiver275 bupwaivproviders prov_outofcounty totalprescribers perc_waiver totbuppat_bypatcty buppatincty_bypatcty methadone_patients Totalslots bupotp_patients ///
	curtreat_all curtreat_all_perc treatcap3 curtreatgap_all treatgap_cap3 ///
	newprov_curtreat newprov_3 cap newprov_cappedcurtreat newprov_capped3 perc_gapfilled_curtreat perc_gapfilled3
	
export excel using "${output}/CA County OUD and Bup_${today}.xlsx", sheetmodify firstrow(varlabels)

restore

log close









