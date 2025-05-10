* Homar A. Maurás Rodríguez
* PPOL 6818 - Assignment 3
* Sampling Noise: Finite vs Infinite Populations

if c(username)=="homi" {
	global wd "/Users/homi/GitHub/ppol6818/ppol6818-ham86/assignments/stata_3"
}

cd "$wd"
set more off
set seed 1099

	/*********************************************
	Part 1: Sampling Noise in Fixed Population
	*********************************************/

clear all
set obs 10000

* DGP: y = 2x + e
gen x = rnormal()
gen e = rnormal()
gen y = 2*x + e

* Save fixed population
save "$wd/population.dta", replace

* Define regression program drawing from population
program define reg_fixed, rclass
	syntax, n(integer)

	use "$wd/population.dta", clear
	sample `n', count

	reg y x
	return scalar N    = e(N)
	return scalar beta = _b[x]
	return scalar sem  = _se[x]
	return scalar p    = 2 * ttail(e(df_r), abs(_b[x]/_se[x]))
	return scalar lb   = _b[x] - 1.96 * _se[x]
	return scalar ub   = _b[x] + 1.96 * _se[x]
end

* Simulate at 4 sample sizes
foreach s in 10 100 1000 10000 {
	simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) lb=r(lb) ub=r(ub), reps(500): ///
		reg_fixed, n(`s')
	save "$wd/results_n`s'.dta", replace
}

* Combine into single dataset
use "$wd/results_n10.dta", clear
gen sample = 10
foreach s in 100 1000 10000 {
	append using "$wd/results_n`s'.dta"
	replace sample = `s' if missing(sample)
}
save "$wd/results_all.dta", replace

* Summarize and plot
collapse (mean) sem beta (sd) beta_sd=beta, by(sample)

twoway line sem sample, ///
	title("Mean SEM vs Sample Size (Fixed Population)") ///
	xtitle("Sample Size") ytitle("Mean SEM")

twoway line beta_sd sample, ///
	title("Standard Deviation of β̂ vs Sample Size") ///
	xtitle("Sample Size") ytitle("SD of Beta")

graph export "$wd/plots/fixed_sem_beta_sd.png", replace

	/*********************************************
	Part 2: Sampling Noise in Infinite Superpopulation
	*********************************************/

program define reg_superpop, rclass
	syntax, n(integer)

	clear
	set obs `n'
	gen x = rnormal()
	gen e = rnormal()
	gen y = 2*x + e

	reg y x
	return scalar N    = e(N)
	return scalar beta = _b[x]
	return scalar sem  = _se[x]
	return scalar p    = 2 * ttail(e(df_r), abs(_b[x]/_se[x]))
	return scalar lb   = _b[x] - 1.96 * _se[x]
	return scalar ub   = _b[x] + 1.96 * _se[x]
end

* List of sample sizes: powers of 2 and 10
local sizes 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 ///
            131072 262144 524288 1048576 2097152 10 100 1000 10000 100000 1000000

* Initialize results file
clear
set obs 0
gen N = .
gen beta = .
gen sem = .
gen p = .
gen lb = .
gen ub = .
save "$wd/results_infinite.dta", replace

* Run simulations and append
foreach n in `sizes' {
	simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) lb=r(lb) ub=r(ub), reps(500): ///
		reg_superpop, n(`n')
	append using "$wd/results_infinite.dta"
	save "$wd/results_infinite.dta", replace
}

* Summary table and plots
use "$wd/results_infinite.dta", clear
gen logN = log(N)

* Beta distribution
twoway (scatter beta N, jitter(3) msymbol(oh) mcolor(%30)) ///
       (lpolyci beta N, degree(1)), ///
       xscale(log) xtitle("Sample Size (log)") ytitle("β̂ Estimate") ///
       title("Beta Estimates by N (Infinite Population)") legend(off) ///
       yline(2, lpattern(dash))
graph export "$wd/plots/beta_infinite.png", replace

* SEM vs N
twoway (scatter sem N, jitter(3) msymbol(oh) mcolor(%30)) ///
       (lpolyci sem N, degree(1)), ///
       xscale(log) yscale(log) xtitle("Sample Size (log)") ytitle("SEM (log)") ///
       title("SEM by Sample Size (Infinite Population)") legend(off)
graph export "$wd/plots/sem_infinite.png", replace

collapse (mean) beta sem (sd) beta_sd=beta (mean) p, by(N)
list N beta beta_sd sem p, sep(0)
