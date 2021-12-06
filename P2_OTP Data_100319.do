/**********************************************************
Name: OTP Counts
Project: CA County Estimates of OUD	
Purpose: OTP Counts of treatment centers and methadone/bup patients
Author: Marni Epstein
Date: September 2017

Notes:
OTP data was sent to us by Kenneth Gandy via a Public Records Act (PRA) request. The original request was sent on 4/8/19.
We received the document called "Provider_Directory_June2019" saved Box\2019 OUD CHCF County Estimates\3 Data\SAMHSA OTP Data
We additionally received counts of buprenorphine and methadone patients by OTP,
	saved as "AMR Patient Dose Level  Cap. as of March 31 2018- PRA_Methadone dosage_Marked"
	and "AMR Patient Dose Level  Cap. as of March 31 2018- PRA_Buprenorphine Dosage_Marked"


For 6 OTPs, Values are not shown to protect confidentiality of the individuals summarized in the data.
3 OTPs did not provide accuate data. 
For these 9 facilities, we assumed that the number of patients was equal to 80% of slots.
***********************************************************/



*Enter user (computer name)
global user = "MEpstein"

*Enter today's date to create unique log
global today=100319

*Set directory and globals
cd "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3b Analysis 2019 Update\Datasets"
gl otp "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\SAMHSA OTP Data"
global crosswalk "D:\Users\\${user}\Box\2019 OUD CHCF County Estimates\3 Data\Geographic Crosswalks\2017"



/***********************************************************
Read in OTP data
Methadone dosing as of April 2019
***********************************************************/

import excel "${otp}\AMR Patient Dose Level  Cap. as of March 31 2018- PRA_Methadone dosage_Marked.xlsx", cellrange(F4:I225) firstrow clear

drop if county == ""

*Check that none have a missing county
tab county, m

*Replace the two OTPs with "Sutter/Yuba" county as Yuba based on a google search
list if county == "Sutter/Yuba"
replace county = "Yuba" if county == "Sutter/Yuba"


*Convert zipcode to numeric to get rid of weird spacing and then back to string to merge with zip to SPA crosswalk
destring zipcode, replace
gen ZIP_CODE=string(zipcode) 


/* Merge with Zip to SPA crosswalk to replace LA County with SPAs */

merge m:1 ZIP_CODE using "${crosswalk}/zip_SPA_crosswalk.dta"

* _m == 1 (from master only) should be all zip codes outside of LA
list county slots methadone_patients zipcode if _m == 1 & county == "Los Angeles"


* _m == 2 are all zip codes that don't have a matching NTP. We don't want to keep these records
drop if _m == 2

replace county="LA SPA " + string(SPA) if county=="Los Angeles" | _m==2 //if county is LA or zip code is in the zip to SPA crosswalk but not the zip to county
replace county= "LA SPA 1 and 5" if county=="LA SPA 1"
drop _m


*Create indicator variable to count OTPs per county. Collapse to the county-level
tab county, m
gen OTPcount=1

rename slots Totalslots

collapse (sum) OTPcount Totalslots methadone_patients, by(county)

save "methadonecounts.dta", replace

/***********************************************************
Merge in bup patients at OTP data, also from the PRA request
***********************************************************/
import excel "${otp}\AMR Patient Dose Level  Cap. as of March 31 2018- PRA_Buprenorphine Dosage_Marked.xlsx", cellrange(A4:E225) firstrow clear
drop if county == ""
drop C
rename Alameda LicenseNum

*Check that none have a missing county
tab county, m

*Replace the two OTPs with "Sutter/Yuba" county as Yuba based on a google search
list if county == "Sutter/Yuba"
replace county = "Yuba" if county == "Sutter/Yuba"

*Replace values of "*", which mean did not provide data, with 0
replace bupotp_patients = "0" if bupotp_patients == "*"
destring bupotp_patients, replace


*Convert zipcode to numeric to get rid of weird spacing and then back to string to merge with zip to SPA crosswalk
destring zipcode, replace
gen ZIP_CODE=string(zipcode) 


/* Merge with Zip to SPA crosswalk to replace LA County with SPAs */

merge m:1 ZIP_CODE using "${crosswalk}/zip_SPA_crosswalk.dta"

* _m == 1 (from master only) should be all zip codes outside of LA
list county LicenseNum zipcode if _m == 1 & county == "Los Angeles"

* _m == 2 are all zip codes that don't have a matching NTP. We don't want to keep these records
drop if _m == 2

replace county="LA SPA " + string(SPA) if county=="Los Angeles" | _m==2 //if county is LA or zip code is in the zip to SPA crosswalk but not the zip to county
replace county= "LA SPA 1 and 5" if county=="LA SPA 1"
drop _m

collapse (sum) bupotp_patients, by(county)

merge 1:1 county using "methadonecounts.dta"
drop _m

label variable bupotp_patients "Buprenorphine patients at OTPs" 
label variable OTPcount "Number of OTPs per county"
label variable Totalslots "Total methadone slots at OTPs"
label variable methadone_patients "Methadone patients at OTPs"

save "OTPcounts.dta", replace










