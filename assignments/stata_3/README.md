# README - Assignment 4: Simulation, Power, and Bias

**Author:** Homar A. Maurás Rodríguez  
**Course:** PPOL 6818 - Experimental Design  

---

## Overview
This assignment consists of three parts that explore statistical power and bias in treatment effect estimation. Part 1 simulates power under individual-level randomization, Part 2 explores power in cluster-randomized settings with varying ICCs and adoption rates, and Part 3 assesses bias and precision across multiple regression models with differing covariate controls.

---

## Part 1: Power Calculations (Individual-Level Randomization)

- A data generating process was simulated where:
  - Outcome \( Y \sim N(0, 1) \)
  - 50% of units were randomly assigned to treatment
  - Treatment effects were drawn uniformly from 0.0 to 0.2
  - Average treatment effect was set to **0.1 SD**

- Using Stata's `power twomeans` command:
  - Required total sample size for 80% power: **3,142**
  - Adjusted for 15% attrition:  
    \[
    N = \frac{3142}{1 - 0.15} \approx 3,696
    \]

- Under a **cost-constrained scenario** where only **30% of individuals** can be treated:
  - Power calculations were adjusted using `nratio(0.3/0.7)`
  - Required sample size increases to **4,424**

---

## Part 2: Power Calculations (Cluster Randomization)

- Simulated school-level randomization:
  - Outcome: simulated test scores per student
  - ICC (rho) set at **0.3**
  - Treatment assigned at the **school (cluster)** level
  - Treatment effect drawn uniformly from **0.15 to 0.25**, with an ATE of 0.2

### Simulation 1: Varying Cluster Size
- Fixed number of clusters = 200
- Cluster size varied across first 10 powers of 2: 2, 4, 8, ..., 1024
- Power increases substantially with larger clusters

### Simulation 2: Varying Number of Clusters
- Cluster size fixed at **15 students**
- Varying number of schools from 40 to 200
- Identified threshold where **power ≥ 0.8** to detect a 0.2 SD effect

### Simulation 3: 70% School-Level Compliance
- Simulated noncompliance where only **70% of treated schools** adopt intervention
- Intent-to-treat analysis shows increased sample size needed for 80% power under partial compliance

---

## Part 3: De-biasing a Parameter Estimate Using Controls

- Developed a data generating process where:
  - Outcome \( Y \) depends on:
    - Treatment (binary)
    - One **confounder** (x1): affects both treatment and outcome
    - One **outcome-only** variable (x2)
    - One **treatment-only** variable (x3)
    - Categorical **strata group** (5 levels)
    - Random error

- Simulated five regression models:
  - **Model A:** No controls  
  - **Model B:** Confounder (x1)  
  - **Model C:** Confounder + x2  
  - **Model D:** All covariates (x1, x2, x3)  
  - **Model E:** Strata fixed effects (`i.strata`)

- Evaluated estimates across increasing sample sizes: 100, 200, 500, 1000, 2000  
- Repeated each model 500 times per sample size

### Figure 1: Mean Estimated Treatment Effects
![Mean Beta Plot](plots/mean_beta_plot.png)
- Bias decreases with better model specification
- Models B through E converge to the true effect (β = 1)
- Model A consistently overestimates treatment effect due to omitted confounders

### Figure 2: Standard Deviation of Treatment Estimates
![SD Beta Plot](plots/sd_beta_plot.png)
- Standard deviation of \( \hat{\beta} \) decreases with N
- More complete models (D and E) demonstrate the lowest variance across simulations

---

## Files Included

- `stata_assignment_4_homar.do` – main simulation and analysis script
- `cluster_power.dta` – output from cluster size simulations
- `model_betasim_output.dta` – results from Part 3 simulations
- `plots/mean_beta_plot.png` – average estimate figure
- `plots/sd_beta_plot.png` – variance figure
