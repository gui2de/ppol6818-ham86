* Homar A. Maurás Rodríguez
* Experimental Design
* STATA PS2

if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="homi" { //this would be your username on your computer
	
	global wd "/Users/homi/GitHub/ppol6818/ppol6818-ham86"
}

	/********************
	TANZANIA STUDENT DATA
	*********************/

/*
This builds on the bonus from the previous Stata assignment. We downloaded the PSLE data of students from 138 schools in Arusha District in Tanzania (previously we only had data of just 1 school) You can build on your code from the previous assignment to create a student level dataset for these 138 schools.
*/

use "/$wd/week_05/03_assignment/01_data/q1_psle_student_raw.dta", clear

gen html_text = s

// extracting school-level information
gen school_name = regexs(1) if regexm(html_text, "([A-Z ]+ PRIMARY SCHOOL)")
gen school_code = regexs(1) if regexm(html_text, "(PS[0-9]+)")
gen num_students = real(regexs(1)) if regexm(html_text, "WALIOFANYA MTIHANI : ([0-9]+)")
gen school_avg = real(regexs(1)) if regexm(html_text, "WASTANI WA SHULE   : ([0-9]+\.[0-9]+)")
gen student_group = "Under 40" if regexm(html_text, "KUNDI LA SHULE : Wanafunzi chini ya 40")
replace student_group = ">=40" if student_group == ""
gen rank_council = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: ([0-9]+) kati ya ([0-9]+)")
gen rank_region = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : ([0-9]+) kati ya ([0-9]+)")
gen rank_national = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENY E KUNDI LAKE KITAIFA : ([0-9]+) kati ya ([0-9]+)")

// expanding for student numbers for 
expand num_students

// extracting student data
gen cand_id = regexs(1) if regexm(html_text, "(PS[0-9]+-[0-9]+)")
gen prem_number = regexs(1) if regexm(html_text, "([0-9]{11})")
gen gender = regexs(1) if regexm(html_text, ">(M|F)<")
gen name = regexs(1) if regexm(s, "[MF].*?<P>([A-Z ]+)<\/FONT><\/TD>")

// extracting grades
gen kiswahili = regexs(1) if regexm(html_text, "Kiswahili - ([A-E])")
gen english = regexs(1) if regexm(html_text, "English - ([A-E])")
gen maarifa = regexs(1) if regexm(html_text, "Maarifa - ([A-E])")
gen hisabati = regexs(1) if regexm(html_text, "Hisabati - ([A-E])")
gen science = regexs(1) if regexm(html_text, "Science - ([A-E])")
gen uraia = regexs(1) if regexm(html_text, "Uraia - ([A-E])")
gen average = regexs(1) if regexm(html_text, "Average Grade - ([A-E])")

keep school_name school_code cand_id prem_number gender name kiswahili english maarifa hisabati science uraia average



	/*******************************
	Côte d'Ivoire Population Density
	*******************************/

/*
We have household survey data and population density data of Côte d'Ivoire. Merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) i.e. add population density column to the CIV_Section_0 dataset.
*/

import excel "/$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.xlsx", firstrow clear
save "/$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta", replace // saving as .dta file

// setting globals
global CIV_population "/$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta"
global CIV_Section_0 "/$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta"

// checking for common var to merge
use "$CIV_population", clear
d
list in 1/5 

use "$CIV_Section_0", clear
d
list in 1/5  // b10_nomvillag = NOMCIRCONSCRIPTION in CIV_population, we have to rename and trim

// trimming and renaming
use "$CIV_population", clear

rename NOMCIRCONSCRIPTION village // renaming for ease of use
replace village = lower(trim(village))

// removing administrative descriptors
replace village = subinstr(village, "district autonome d'", "", .)
replace village = subinstr(village, "departement d'", "", .)
replace village = trim(village)  // trimming extra spaces

// collapsing to village level
collapse (sum) POPULATION SUPERFICIEKM2 DENSITEAUKM, by(village)

// saving cleaned population density data
save "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity_cleaned.dta", replace
global CIV_population_clean "/$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity_cleaned.dta"


// switching to CIV_Section_0
use "$CIV_Section_0", clear

// renaming and trimming
rename b10_nomvillag village // now we have a common varname
replace village = lower(trim(village))

// merging population density data into household data using department name
merge m:1 village using "$CIV_population_clean"

// dropping unnecessary columns and missing obs
drop _merge
drop if missing(POPULATION) | missing(SUPERFICIEKM2) | missing(DENSITEAUKM)

// saving as merged dataset
save "$wd/week_05/03_assignment/01_data/q2_CIV_merged.dta", replace



	/*********************************
	Enumerator Assignment based on GPS
	*********************************/

/*
We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other (this would reduce the amount of time they spend walking from one house to another.) Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (i.e. add a column and assign it a value 1-19 which can be used as enumerator ID). Note: Your code should still work if I run it on data from another village.
*/

use "/$wd/week_05/03_assignment/01_data/q3_GPS Data.dta", clear

// cleaning latitude and longitude
destring latitude longitude, replace force

// computing min and max for latitude and longitude
egen min_lat = min(latitude)
egen max_lat = max(latitude)
egen min_lon = min(longitude)
egen max_lon = max(longitude)

// standardizing latitude and longitude for clustering
gen lat_scaled = (latitude - min_lat) / (max_lat - min_lat)
gen lon_scaled = (longitude - min_lon) / (max_lon - min_lon)

// performing hierarchical clustering using Ward's method
cluster wardslinkage lat_scaled lon_scaled, name(household_clusters)

// cutting dendrogram into 19 groups (for 19 enumerators)
cluster generate enumerator_id = group(19)



	/***********************************
	2010 Tanzania Election Data Cleaning
	***********************************/

/*
2010 election data (Tz_election_2010_raw.xlsx) from Tanzania is not usable in its current format. You have to create a dataset in the wide form, where each row is a unique ward, and votes received by each party are given in separate columns. You can check the following dta file as a template for your output: Tz_elec_template. Your objective is to clean the dataset in such a way that it resembles the format of the template dataset.
*/

// Importing raw election data from Excel
import excel "/$wd/week_05/03_assignment/01_data/q4_Tz_election_2010_raw.xls", firstrow cellrange(A5) clear

// Dropping unnecessary columns
capture drop K  // Dropping column K
capture drop G  // Dropping column G (SEX already represents gender)

// Dropping the first row if it's an extra header
capture drop in 1

// Filling down missing values in REGION, DISTRICT, CONSTITUENCY, and WARD
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if missing(`var')
}

// Handling missing values
replace SEX = "F" if missing(SEX)  // Default missing SEX values to Female
replace ELECTEDCANDIDATE = "Not Selected" if missing(ELECTEDCANDIDATE)

// Cleaning numeric columns (like TTLVOTES) by removing extra text
replace TTLVOTES = subinstr(TTLVOTES, " votes", "", .)  
destring TTLVOTES, replace force  

// Generating separate columns for each party's votes dynamically
levelsof POLITICALPARTY, local(parties)  

foreach party of local parties {
    local party_clean = subinstr("`party'", " ", "_", .)   // Replacing spaces with underscores
    local party_clean = subinstr("`party_clean'", "-", "_", .)  // Replacing hyphens with underscores
    local party_clean = subinstr("`party_clean'", ".", "", .)  // Removing dots if present

    di "`party_clean'"   // Debugging: Print cleaned party name

    capture gen VOTES_`party_clean' = 0  // Use capture to avoid errors if column exists
    replace VOTES_`party_clean' = TTLVOTES if POLITICALPARTY == "`party'"
}

// Creating ward_id_10 as a unique identifier for each ward
gen ward_id_10 = REGION + "_" + DISTRICT + "_" + COSTITUENCY + "_" + WARD

// Counting the total number of candidates per ward
bysort ward_id_10: gen total_candidates_10 = _N

// Calculating the total votes in each ward
bysort ward_id_10 (TTLVOTES): gen ward_total_votes_10 = sum(TTLVOTES)
bysort ward_id_10 (TTLVOTES): replace ward_total_votes_10 = ward_total_votes_10[_N]  // Keep the final sum for each ward



	/*****************
	Tanzania PSLE data
	*****************/

/*
PSLE dataset contains data of 17,329 schools. We have the region and district of each school but for our analysis we need the ward information. There is another dataset (q5_school_location) that has the ward information of 19,733 schools. Your job is to identify ward information for 17,329 schools on the PSLE dataset using the q5_school_location.dta. Note: Final dataset should be the PSLE dataset + ward column (i.e. N = 17,329). Hint: You might have to try different methods to get the best results, even then you might have some schools where we can't find ward information. */

// Setting globals
global PSLE_raw "/$wd/week_05/03_assignment/01_data/q5_psle_2020_data.dta"
global PSLE_location "/$wd/week_05/03_assignment/01_data/q5_school_location.dta"

use "$PSLE_raw", clear

// Standardizing school names: Convert to lowercase and trim spaces
gen school_clean = lower(schoolname)
replace school_clean = trim(school_clean)

// Removing common variations (punctuation, abbreviations)
replace school_clean = subinstr(school_clean, ".", "", .)
replace school_clean = subinstr(school_clean, ",", "", .)
replace school_clean = subinstr(school_clean, " primary school", "", .) 
replace school_clean = subinstr(school_clean, " p.s", "", .) 
replace school_clean = subinstr(school_clean, " sec school", " secondary", .)

// Extracting school name before the hyphen (if ID exists)
gen school_clean_short = regexs(1) if regexm(school_clean, "(.+?) - ps[0-9]+")
replace school_clean_short = school_clean if school_clean_short == ""

// Trimming spaces for consistency
replace school_clean_short = trim(school_clean_short)

// Verifying extraction
list school_clean school_clean_short if _n <= 20

// Saving clean dataset with new variable
save "/$wd/week_05/03_assignment/01_data/q5_psle_2020_data_clean.dta", replace
global PSLE_clean "/$wd/week_05/03_assignment/01_data/q5_psle_2020_data_clean.dta"


// Loading school location data

use "$PSLE_location", clear

// Standardizing school names: Convert to lowercase and trim spaces
gen school_clean = lower(School)
replace school_clean = trim(school_clean)

// Removing common variations (punctuation, abbreviations)
replace school_clean = subinstr(school_clean, ".", "", .)
replace school_clean = subinstr(school_clean, ",", "", .)
replace school_clean = subinstr(school_clean, " primary school", "", .) 
replace school_clean = subinstr(school_clean, " p.s", "", .) 
replace school_clean = subinstr(school_clean, " sec school", " secondary", .)

// Keeping only necessary columns
keep school_clean Ward

// Checking for duplicates
duplicates report school_clean

// Listing duplicate cases if they exist
duplicates list school_clean if _N > 1

// Deduplicating: Keeping the most common ward per school
bysort school_clean Ward: gen ward_count = _N
bysort school_clean (ward_count): replace Ward = Ward[_N]
duplicates drop school_clean, force
drop ward_count

// Saving cleaned school location dataset
save "/$wd/week_05/03_assignment/01_data/q5_school_location_unique.dta", replace
global PSLE_location_unique "/$wd/week_05/03_assignment/01_data/q5_school_location_unique.dta"

// Loading cleaned PSLE dataset
use "$PSLE_clean", clear

// Merging school location data
merge m:1 school_clean using "$PSLE_location_unique"

// Checking merge results
tab _merge
drop _merge

// Saving merged dataset
save "/$wd/week_05/03_assignment/01_data/q5_psle_merged.dta", replace
