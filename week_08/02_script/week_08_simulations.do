/*
PPOl 6818
Ali Hamza
Week 8 
March 12, 2025


Additional Resources:
https://www.stata.com/manuals/u18.pdf
https://www.stata.com/manuals13/psyntax.pdf
*/



*How to define a program in Stata
capture program drop hello
program define hello
	display as red "Hi there"
end 

capture program drop xyz

program define xyz 
	corr `1' `2' `3'
end


sysuse auto, clear

xyz price mpg weight



*How to define a program: Arguments
capture program drop listargs
program define listargs
display as error "The is the whole argument you typed: `0'"
display as error "The is the whole argument you typed (trimmed): `*'"

display as error "The 1st argument you typed is: `1'"
display as error "The 2nd argument you typed is: `2'"
display as error "The 3rd argument you typed is: `3'"
display as error "The 4th argument you typed is: `4'"
display as error "The 5th argument you typed is: `5'"
display as error "The 6th argument you typed is: `6'"
end  


*Example 
capture program drop abc
program define abc
		args dep_var ind_var1 ind_var2
	display as error "The 1st argument you typed is: `1'"
	display as error "The 1st argument you typed is: `dep_var'"
	display as error "The 2nd argument you typed is: `2'"
	display as error "The 2nd argument you typed is: `ind_var1'"
	display as error "The 3rd argument you typed is: `3'"
	display as error "The 2nd argument you typed is: `ind_var2'"
end  


abc price model mpg


*Example
capture program drop normal_dist
program define normal_dist
	clear 
	set obs 100
	gen age = rnormal(45,8)
end 


clear
normal_dist


*Example
capture program drop normal_dist
program define normal_dist
	args obs_num varname random_mean random_sd
	clear 
	set obs `obs_num'
	gen `varname' = rnormal(`random_mean',`random_sd')
end 

clear
normal_dist 1000 math_score 65 12



*How to define a program using syntax option
capture program drop normal_dist_v2
program define normal_dist_v2
	syntax, obs(integer) varname(string) mean(real) sd(real)
	
	clear 
	set obs `obs'
	gen `varname' = rnormal(`mean',`sd')

end

*Example
normal_dist_v2, obs(100) varname(height)  mean(60) sd(10)

 

 
 
 
*Example of Simulations
power twomeans 100 110, sd1(50) sd2(50)

clear
tempfile results
save `results', emptyok

  clear
  set seed 2023

  *input parameters
  local samplesize = 788
  local m1 = 100
  local m2 = 110
  local sd1 = 50
  local sd2 = 50 
  local treat_num = `samplesize'/2
  
forvalues i=1/1000 {
	
	
  clear 
  set obs `samplesize'
  *generate dummy variable for treatment 
  gen rand = rnormal()  // 50-50 treatment
    egen rank = rank(rand)
    gen treatment = rank <= `treat_num'
  
  *data generating process
*generate dependent variable  
  gen dep_var = rnormal(`m1', `sd1')  if treatment==0
  replace dep_var = rnormal(`m2', `sd2') if treatment == 1

  reg dep_var treatment
  
  
  mat a = r(table)
  matrix list  a
	
	clear 
	set obs 1
	gen iteration = `i'
	gen reg_coef = a[1,1]
	gen reg_pval = a[4,1]

	append using `results'
	save `results', replace
}

use `results', clear 














