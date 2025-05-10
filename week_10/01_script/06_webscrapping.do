*PPOL 6818
*Week 10
*Ali Hamza
*March 26th, 2025

*How comfortable do you feel reading the code without any comments?




*Download PSLE 2022 results: https://onlinesys.necta.go.tz/results/2022/psle/psle.htm

clear
tempfile schools
save `schools', replace emptyok


*
clear
set obs 1
gen s = fileread("https://onlinesys.necta.go.tz/results/2022/psle/results/distr_0101.htm")
display s[1]

split s, parse("<A HREF=") gen(var)

gen serial = _n

drop s
reshape long var, i(serial) j(j)

keep if regex(var, "shl_ps")==1
replace var = stritrim(strtrim(var))


rename var string
split string, parse(">") gen(var)

keep var1 

rename var1 district_code_raw
replace district_code_raw = subinstr(district_code_raw,`"""', "",.)

tempfile district_codes
save `district_codes'


count 

forvalues i=1/`r(N)' {
clear
use `district_codes', clear

keep in `i'

local address = district_code_raw[1]

gen s = fileread("https://onlinesys.necta.go.tz/results/2022/psle/results/`address'")

append using `schools'
save `schools', replace 

}

use `schools', clear 


