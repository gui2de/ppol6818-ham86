*Homar A. Maurás Rodríguez
*PPOL 6818 STATA Assignment 1

// setting directories

if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="homi" { //this would be your username on your computer
	
	global wd "/Users/homi/GitHub/ppol6818/ppol6818-ham86"
}

////////////////////////////////////////////////////////////////////////////////
**# QUESTION 1
////////////////////////////////////////////////////////////////////////////////

/*
As part of a larger examination of how various factors contribute to student achievement, you have been asked to find a couple of pieces of information about a school district. Unfortunately, the relevant data is spread across four different files (student.dta, teacher.dta, school.dta, and subject.dta all in the following subfolder: q1_data. See the readme file for more details regarding each dataset.
*/

global q1_school "$wd/week_03/04_assignment/01_data/q1_data/school.dta"
global q1_student "$wd/week_03/04_assignment/01_data/q1_data/student.dta"
global q1_subject "$wd/week_03/04_assignment/01_data/q1_data/subject.dta"
global q1_teacher "$wd/week_03/04_assignment/01_data/q1_data/teacher.dta"

** (a) What is the mean attendance of students at southern schools?

// checking for common variables
use "$q1_student", clear // does not include school info, will possibly need to replace grade to school level
use "$q1_school", clear
use "$q1_teacher", clear // contains school information
use "$q1_subject", clear

// merging teacher + school
use "$q1_teacher", clear

merge m:1 school using "$q1_school" // successfully merged
drop _merge

// saving under new file
save "$wd/week_03/04_assignment/01_data/q1_data/merged.dta", replace
global q1_merged "$wd/week_03/04_assignment/01_data/q1_data/merged.dta"
use "$q1_merged", clear

// merging merged (sch +teach) + subject
merge m:1 subject using "$q1_subject" // successfully merged
drop _merge
save "$q1_merged", replace

// merging merged (sch+teach+subj) + student
rename teacher primary_teacher
merge 1:m primary_teacher using "$q1_student" // successfully merged
drop _merge
rename primary_teacher teacher_id
save "$q1_merged", replace

//mean attendance of southern school
sum attendance if loc == "South"


** (b) Of all students in high school, what proportion of them have a primary teacher who teaches a tested subject?
gen high_stdnt = .
replace high = 1 if level == "High"
replace high = 0 if missing(high_stdnt)

bysort tested: tab subject // Math, Reading/Writing, and Science are tested

gen tested_teach = (subject == "Math" | subject == "Reading/Writing" | subject == "Science")

tab high if tested_teach == 1


** (c) What is the mean gpa of all students in the district?
sum gpa


* (d) What is the mean attendance of each middle school? 
gen middle_school = ""
replace middle_school = school if level == "Middle"

bysort middle_school: sum attendance


////////////////////////////////////////////////////////////////////////////////
**# QUESTION 2
////////////////////////////////////////////////////////////////////////////////

use "$wd/week_03/04_assignment/01_data/q2_village_pixel.dta", clear

/*
a)	Payout variable should be consistent within a pixel, confirm if that is the case. Create a new dummy variable (pixel_consistent), this variable =0 if payout variable isn't consistent within that pixel (i.e. =1 when all the payouts are exactly the same, =0 if there is even a single different payout in the pixel) 
*/

// checking if pixels are repeated by payout
bys pixel: tab payout // looks like payouts are uniform within pixels

// generating max and min payouts
bys pixel: egen max_payout = max(payout)
bys pixel: egen min_payout = min(payout)

// checking for pixel consistency in payout
bys pixel: gen pixel_consistent = (max_payout == min_payout)
codebook pixel_consistent // this seems to be the case


/*
b)	Usually the households in a particular village are within the same pixel but it is possible that some villages are in multiple pixels (boundary cases). Create a new dummy variable (pixel_village), =0 for the entire village when all the households from the village are within a particular pixel, =1 if households from a particular village are in more than 1 pixel. Hint: This variable is at village level.
*/

// tagging first obs of each pixel for village
bys village pixel: gen tag = _n == 1
bys village: gen n_pixels = sum(tag)

// 1: village in more than one pixel    0: in one pixel
gen pixel_village = (n_pixels > 1)
codebook pixel_village

tab vill if pixel_village == 1


/*
c)	For this experiment, it is only an issue if villages are in different pixels AND have different payout status. For this purpose, divide the households in the following three categories:
	i.	Villages that are entirely in a particular pixel. (==1)
	ii.	Villages that are in different pixels AND have same payout status (Create a list of all hhids in such villages) (==2)
	iii. Villages that are in different pixels AND have different payout status (==3)

Hint: These 3 categories are mutually exclusive AND exhaustive i.e. every single observation should fall in one of the 3 categories. Note also that the categories may or may not line up with what you created in (a) and (b) so read the instructions closely.
*/

gen hh_status = .

// hh if village entirely in pixel
replace hh_status = 1 if pixel_village == 0

// hh if village is in > 1 pixel & same payout
bys village payout: gen pay_tag = _n == 1
bys village: egen n_payout = sum(pay_tag)
gen payout_consistent = (n_payout == 1) // 1: 1 payout    0: > 1 payout
replace hh_status = 2 if pixel_village == 1 & payout_consistent == 1

// hh if village > 1 pixel & different payout
replace hh_status = 3 if pixel_village == 1 & payout_consistent == 0
codebook hh_


////////////////////////////////////////////////////////////////////////////////
**# QUESTION 3
////////////////////////////////////////////////////////////////////////////////

/*
Faculty members submitted 128 proposals for funding opportunities. Unfortunately, we only have enough funding for 50 grants. 

Each proposal was assigned randomly to three selected reviewers who each gave a score between 1 (lowest) and 5 (highest). 

Each person reviewed 24 proposals and assigned a score. We think it will be better if we normalize the score wrt each reviewer (using unique ids) before calculating the average score. 

Add the following columns 1) stand_r1_score 2) stand_r2_score 3) stand_r3_score 4) average_stand_score 5) rank (Note: highest score =>1, lowest => 128)

Hint: We can normalize scores using the following formula: (score – mean)/sd, where mean = mean score of that particular reviewer (based on the netid), sd = standard deviation of scores of that particular reviewer (based on that netid). (Hint: we are not standardizing the score wrt reviewer 1, 2 or 3. But by the netID.)
*/

use "$wd/week_03/04_assignment/01_data/q3_proposal_review.dta", clear

// renaming vars
rename proposal_id prop_id
rename *, lower // making all variables lower case
rename rewiewer1 reviewer1 // fixing typo
rename averagescore avg_score
rename standarddeviation stdev

local n = 1
foreach var in review1score reviewer2score reviewer3score {
	rename `var' score`n'
	local n = `n' + 1
}

// dropping unnecessary variables
drop pi department

// reshaping to long format
reshape long score reviewer, i(prop_id) j(reviewer_num)

// adding columns
foreach n in 1 2 3{
	bys reviewer: egen mean_score`n' = mean(score)
	gen stand_r`n'_score = (mean_score`n' - avg_score) / stdev	
}

gen average_stand_score = (mean_score1 + mean_score2 + mean_score3) / 3

gsort -average_stand_score  
gen rank = _n               

list rank prop_id reviewer score if _n <= 10


////////////////////////////////////////////////////////////////////////////////
**# QUESTION 4
////////////////////////////////////////////////////////////////////////////////

/*
We have the information of adults that have computerized national ID card in the following pdf: Pakistan_district_table21.pdf. This pdf has 135 tables (one for each district). We extracted data through an OCR software but unfortunately it wasn't very accurate. We need to extract column 2-13 from the first row ("18 and above") from each table. Create a dataset where each row contains information for a particular district. The hint do file contains the code to loop through each sheet, you need to find a way to align the columns correctly.
Hint: While the formatting is mostly regular, there are a couple of (pretty minor) anomalies so be sure to look at what your code produces.*/


global excel_t21 "$wd/week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"

import excel "$excel_t21", clear

clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	keep B C D E F G H I J K L M // keeping relevant columns
	foreach var of varlist B C D E F G H I J K L M {
		replace `var' = trim(`var')
	}
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear

destring B C D E F G H I J K L M, replace ignore("N/A")

list B C D E F G H I J K L M in 1/10

////////////////////////////////////////////////////////////////////////////////
**# QUESTION 5	
////////////////////////////////////////////////////////////////////////////////

use "$wd/week_03/04_assignment/01_data/q5_Tz_student_roster_html.dta", clear

// extracting html_text
gen html_text = s

// extracting school name
gen school_name = regexs(1) if regexm(html_text, "([A-Z ]+ PRIMARY SCHOOL)")

// extract school code
gen school_code = regexs(1) if regexm(html_text, "(PS[0-9]+)")

// extract number of students
gen num_students = real(regexs(1)) if regexm(html_text, "WALIOFANYA MTIHANI : ([0-9]+)")

// extracting school average
. gen school_avg = real(regexs(1)) if regexm(html_text, "WASTANI WA SHULE   : ([0-9]+\.[0-9]+)")

// extract student group
gen student_group = "Under 40" if regexm(html_text, "KUNDI LA SHULE : Wanafunzi chini ya 40")

replace student_group = ">=40" if student_group == ""

// extracting SR in council
gen rank_council = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI: ([0-9]+) kati ya ([0-9]+)")

// extracting SR in region
gen rank_region = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA  : ([0-9]+) kati ya ([0-9]+)")

// extract national SR
gen rank_national = regexs(1) + " out of " + regexs(2) if regexm(html_text, "NAFASI YA SHULE KWENY E KUNDI LAKE KITAIFA : ([0-9]+) kati ya ([0-9]+)")

keep school_name school_code num_students school_avg student_group rank*

