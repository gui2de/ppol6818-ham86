*PPOL 6818
*Week 10
*Ali Hamza
*March 26th, 2025


clear
set more off
set seed 2025



capture program drop coin_flip
program define coin_flip, rclass
syntax, obs(integer)

*clear memory and set obs
clear
set obs  `obs'

*generate random variable to simulate coinflip
gen coin_random = runiform() //generate using random uniform dist between 0 and 1

*50% probability of H vs T
gen coin_heads = 0
replace coin_heads = 1 if coin_random>0.5

*calculate mean 
summ coin_heads

*store mean in r(heads)
return scalar heads = `r(mean)'
end 

coin_flip, obs(100)
display `r(heads)'


