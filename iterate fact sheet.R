###################################################
# Iterate program to run all fact sheets
###################################################

library(rmarkdown)
library(stringr)
library(tidyverse)


Sys.setenv(PATH = "C:\\Rtools\\bin;D:\\Users\\Mepstein\\Documents\\R\\R-3.4.3\\bin\\x64;C:\\ProgramData\\Oracle\\Java\\javapath;C:\\Program Files\\Intel\\iCLS Client\\;C:\\windows\\system32;C:\\windows;C:\\windows\\System32\\Wbem;C:\\windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Program Files\\Intel\\Intel(R) Management Engine Components\\DAL;C:\\Program Files (x86)\\Intel\\Intel(R) Management Engine Components\\DAL;C:\\Program Files\\Intel\\Intel(R) Management Engine Components\\IPT;C:\\Program Files (x86)\\Intel\\Intel(R) Management Engine Components\\IPT;C:\\Program Files\\SASHome\\Secure\\ccme4;C:\\Program Files\\SASHome\\SASFoundation\\9.4;C:\\Program Files (x86)\\Microsoft SQL Server\\100\\Tools\\Binn\\;C:\\Program Files\\Microsoft SQL Server\\100\\Tools\\Binn\\;C:\\Program Files\\Microsoft SQL Server\\100\\DTS\\Binn\\;C:\\Program Files\\Citrix\\System32\\;C:\\Program Files\\Citrix\\ICAService\\;D:\\Users\\Mepstein\\AppData\\Local\\Programs\\MiKTeX 2.9\\miktex\\bin\\x64" )

counties <- c("Alameda", "Alpine",	"Amador",	"Butte",	"Calaveras",	"Colusa",	"Contra Costa",	"Del Norte",	"El Dorado",	"Fresno",	"Glenn")

# WITHOUT LA SPAs

counties <- c("Alameda",	"Alpine",	"Amador",	"Butte",	"Calaveras",	"Colusa",	"Contra Costa",	"Del Norte",	"El Dorado",	"Fresno",	"Glenn",	"Humboldt",	"Imperial",	"Inyo",	"Kern",	"Kings", "Lake",	"Lassen",	"Madera",	"Marin",	"Mariposa",	"Mendocino",	"Merced",	"Modoc",	"Mono",	"Monterey",	"Napa",	"Nevada",	"Orange",	"Placer",	"Plumas",	"Riverside",	"Sacramento",	"San Benito",	"San Bernardino",	"San Diego",	"San Francisco",	"San Joaquin",	"San Luis Obispo",	"San Mateo",	"Santa Barbara",	"Santa Clara",	"Santa Cruz",	"Shasta",	"Sierra",	"Siskiyou",	"Solano",	"Sonoma",	"Stanislaus",	"Sutter",	"Tehama",	"Trinity",	"Tulare",	"Tuolumne",	"Ventura",	"Yolo",	"Yuba")

runs <- tibble(
  filename = str_c(counties, ".pdf"), #this creates a string with the countyname.pdf
  params = map(counties, ~list(county = .)))
#County is the param name from the RMD file, counties is the list. I can add more parameters here as well

## Run for each county 
runs %>%
  select(output_file = filename, params) %>%
  pwalk(rmarkdown::render, input = "Factsheet_2019_Update_v7.Rmd", output_dir = "Output/V7/", encoding = "UTF-8")

#pwalk means for every row in the dataframe, run this function (like a for loop that runs on all rows)

#Run LA SPAs
SPAs <- c("LA SPA 2",	"LA SPA 3",	"LA SPA 4",	"LA SPA 6",	"LA SPA 7",	"LA SPA 8")

runs <- tibble(
  filename = str_c(SPAs, ".pdf"), #this creates a string with the countyname.pdf
  params = map(SPAs, ~list(county = .)))
#County is the param name from the RMD file, counties is the list. I can add more parameters here as well

## Run for all the LA SPAs 
runs %>%
  select(output_file = filename, params) %>%
  pwalk(rmarkdown::render, input = "Fact_Sheet_Template_v17_LA_SPAs.Rmd", output_dir = "Output/v17 LA revision/", encoding = "UTF-8")










### OLD VERSIONS


## Run 34 % seek treatment 
runs %>%
  select(output_file = filename, params) %>%
  pwalk(rmarkdown::render, input = "Fact Sheet Template v5 34 perc Seek Tx.Rmd", output_dir = "Output/34 Percent Seek Tx/", encoding = "UTF-8")


## Run 19% seek treatment and max is half waiver capacity
runs %>%
  select(output_file = filename, params) %>%
  pwalk(rmarkdown::render, input = "Fact Sheet Template v5 19 perc Seek Tx Half Capacity Max.Rmd", output_dir = "Output/19 Percent and Half Max Waiver Capacity/", encoding = "UTF-8")



#rmarkdown::render(input = "Fact Sheet Template v5.Rmd", output_dir = "Output/", output_file="Test.pdf", encoding = "UTF-8")
