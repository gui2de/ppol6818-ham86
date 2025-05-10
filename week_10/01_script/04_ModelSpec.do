
*clear memory
clear
set seed 2024101
set obs 100 //create a dataset of 100 obs

*generate confounder variable

gen confounder = rnormal()

*generate treatment, where confounder variables plays a role 
gen random_treatment = runiform()  + 0.8*confounder
*gen dummy for treatment
gen treatment = 0

summ random_treatment , d
*divide the data 50:50 into treatment and control 
replace treatment = 1 if random_treatment>=`r(p50)'

*DGP: outcome variable is affected by treatment + confounder  
gen outcome_var = rnormal() + 2.2*confounder + 5.5*treatment 


*see regression results
reg outcome_var treatment
reg outcome_var treatment confounder 

