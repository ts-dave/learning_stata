clear
set more off
cd "C:\Users\emson\Desktop\Files\Code\Stata\learning_stata\Robust Biostat"



*********Session 1 Introduction and Revision****************

//Sampling distribution of sample mean

// Step 1: Simulate systolic blood pressure data for 100 individuals
clear
set obs 100 // Population of 100 people
gen id = _n // Create an ID for each individual
gen systolic_bp = round(rnormal(120, 15)) // Simulate systolic BP and store as integer
save systolic_bp.dta, replace // Save the dataset as systolic_bp.dta

// Step 2: Remove any existing file that might cause conflict
cap erase sample_means.dta // Delete the file if it already exists

// Step 3: Set up a postfile to store the sample means for 1000 repetitions
tempname results
postfile `results' sample_mean using sample_means.dta

// Step 4: Set the seed for reproducibility
set seed 12345

// Step 5: Loop through 100000 repetitions to sample 10 individuals, calculate sample mean
forval i = 1/100000 {
    // Use the original dataset for sampling
    preserve
    use systolic_bp.dta, clear
    
    // Sample 10 individuals
    bsample 10
    
    // Calculate the sample mean
    quietly summarize systolic_bp
    local mean = r(mean)
    
    // Post the sample mean to the postfile
    post `results' (`mean')
    
    // Restore original dataset
    restore
}

// Step 6: Close the postfile
postclose `results'

// Step 7: Load the dataset containing sample means
use sample_means.dta, clear

// Step 8: Plot the histogram of the sample means
histogram sample_mean, normal /// 
    title("Histogram of Sample Means for Systolic BP") ///
    xlabel(115(5)125) ///
    ylabel(, grid) ///
    legend(off)


*********Example 1

import excel "/Users/samuelbosomprah/Documents/Sam/Stuffs/SPH/Dept of Biostatistics/MSc in Biostatistics/Teaching materials/BSTT607_Robust statistics/dataset/example1.xlsx", sheet("dataset") firstrow clear

save example1,replace

use example1, clear

//plots
hist fasting_blood_glucose, norm
graph box fasting_blood_glucose
qnorm fasting_blood_glucose

// summary statistic
tabstat fasting_blood_glucose, statistics(n mean med sd sk)


****Example 2:

import excel "/Users/samuelbosomprah/Documents/Sam/Stuffs/SPH/Dept of Biostatistics/MSc in Biostatistics/Teaching materials/BSTT607_Robust statistics/dataset/example2.xlsx", sheet("dataset") firstrow clear

label define symptoms 0 "Slight or no symptoms" 1 "Marked symptoms"
label value symptoms symptoms
tab symptoms
save example2,replace
use example2,clear

tabstat thyroxine,by(symptoms) s(n mean sd)


****Example 3

import excel "/Users/samuelbosomprah/Documents/Sam/Stuffs/SPH/Dept of Biostatistics/MSc in Biostatistics/Teaching materials/BSTT607_Robust statistics/dataset/example3.xlsx", sheet("Sheet1") firstrow clear

save example3,replace
use example3,clear

twoway scatter th8 th4



// Practical 1

*** skewed data****
use example1, clear

//plots
hist fasting_blood_glucose, norm
graph box fasting_blood_glucose
qnorm fasting_blood_glucose

// summary statistic
tabstat fasting_blood_glucose, statistics(n mean med sd sk)

***Outlier****

/*The following data (from Dunn, 1992, Statistical Methods in Medical Research, 1, 123–157)
are from a small study in which 12 clinical psychology students were asked to complete the
12-item version of the General Health Questionnaire (GHQ) on one day, and then again
three days later. The score is just the sum of the 12 item responses, each 0–3. Hence the
possible range is 0–36.*/

import excel "/Users/samuelbosomprah/Documents/Sam/Stuffs/SPH/Dept of Biostatistics/MSc in Biostatistics/Teaching materials/BSTT607_Robust statistics/dataset/prac1_ghq.xlsx", sheet("Sheet1") firstrow clear

save prac1_ghq,replace
use prac1_ghq,clear

tabstat ghq1 ghq2, statistics(me med sd sk) //suggest strongly that these data are very skewed, to the extent that we might regard the two largest values in each set as "outliers". The box plots confirm this
graph box ghq1 ghq2

mean ghq1 ghq2 //The asymmetry of the data suggest strongly that the normal-based CI's are not appropriate.

gen diff=ghq2-ghq1
tabstat diff, statistics(mean med sd sk) //On the other hand, the differences are much better behaved

mean diff //The 95% confidence interval (and associated paired t-test) are quite acceptable. We learn from this that while particular variables may display large deviations from normality, differences among them may be much better behaved.

corr ghq1 ghq2 //This is moderately high, as one would expect
graph twoway scatter ghq1 ghq2 //The two outlying values look as though they may be rather influential

drop if ghq1 > 20
corr ghq1 ghq2 //This is a rather smaller correlation. Can we estimate correlations that are less sensitive to outliers, and to underlying linearity?


****End of Session 1******



******Session 2 Robust estimators******

clear
set more off
cd "C:\Users\emson\Desktop\Files\Code\Stata\learning_stata\Robust Biostat"

set obs 100 // Simulate 100 participants

// Step 1: Generate ID variable
gen id = _n // Create a unique ID for each participant

// Step 2: Set seed and generate intervention variable (0 = control, 1 = intervention)
set seed 12345
gen intervention = runiform() > 0.5 // Randomly assign intervention to 50% of participants

// Step 3: Set seed and generate age variable (random, with a realistic distribution)
set seed 54321
gen age = round(runiform(30, 70)) // Age between 30 and 70 years

// Step 4: Set seed and generate sex variable (0 = male, 1 = female)
set seed 67890
gen sex = runiform() > 0.5 // Randomly assign sex

// Step 5: Set seed and generate systolic blood pressure (sbp) with different variances for control and intervention
set seed 98765
gen sbp = .
replace sbp = round(rnormal(135, 20)) if intervention == 0 // Control group with smaller variance
replace sbp = round(rnormal(120, 10)) if intervention == 1 // Intervention group with larger variance

// Step 6: Introduce some outliers in sbp to break the normal distribution
replace sbp = sbp + 70 if id == 70 // Add an outlier
replace sbp = sbp + 80 if id == 49 // Add an outlier
replace sbp = sbp + 70 if id == 6 // Add an outlier
replace sbp = sbp + 80 if id == 81 // Add an outlier
replace sbp = sbp + 70 if id == 93 // Add an outlier
replace sbp = sbp + 30 if id == 50 // Add another outlier
replace sbp = sbp - 50 if id == 120 // Add a low outlier

// Step 7: Label the variables for clarity
label variable id "Participant ID"
label variable intervention "Intervention (0=Control, 1=Intervention)"
label variable age "Age"
label variable sex "Sex (0=Male, 1=Female)"
label variable sbp "Systolic Blood Pressure"

// Step 8: Summarize the dataset to check the simulation
summarize

// Step 9: Save the dataset
save cohort_sbp.dta, replace

use cohort_sbp,clear

graph box sbp, by(intervention)
hist sbp, by(intervention) norm

tabstat sbp, by(intervention) s(n mean med sd sk)
sdtest sbp,by(intervention)

**** calculate the  k -trimmed mean for both the control and intervention groups.
/*To calculate an appropriate  k -trimmed mean to normalize the data for each group (control and intervention) in your dataset, we'll first need to determine the value of  k  (the percentage of values to trim from both ends of the sorted data). Once  k  is defined, the trimmed mean will be calculated by excluding the highest and lowest  k % of observations in each group and averaging the remaining values*/

// load dataset 
use cohort_sbp,clear

// Step 1: Define the value of k (e.g., 10% trimming)
local k = 0.10 // This means 10% trimming

// Step 2: Sort the dataset by intervention status and systolic blood pressure (sbp)
sort intervention sbp

// Step 3: Calculate the number of observations to trim for each group
* Get total number of observations in each group
bysort intervention: gen n_group = _N

* Calculate the number of observations to trim from each end (k%)
gen trim_n = ceil(n_group * `k') // Ceiling function ensures whole number of trimmed values

// Step 4: Flag the values to include in the trimmed mean calculation
gen to_keep = 1 // Default to keep all values
bysort intervention (sbp): replace to_keep = 0 if _n <= trim_n // Trim the lowest k%
bysort intervention (sbp): replace to_keep = 0 if _n > n_group - trim_n // Trim the highest k%

// Step 5: Calculate the k-trimmed mean for each group
tabstat sbp if to_keep==1, by(intervention) s(n mean med sd sk)
graph box sbp if to_keep==1, by(intervention)
hist sbp if to_keep==1, by(intervention) norm


*******calculate the  k -winsorized mean for each group in the dataset (control and intervention).
/*To calculate the  k -winsorized mean, you need to replace the lowest and highest  k % of values in a dataset with the  k -th percentile and  (1 - k) -th percentile values, respectively. This process ensures that extreme values are not removed (as with trimmed means) but are instead replaced by values closer to the center of the distribution.*/

// load dataset 
use cohort_sbp,clear

// Step 1: Define the value of k (e.g., 10% winsorizing)
local k = 10 // This means 10% winsorizing

// Step 2: Sort the dataset by intervention status and systolic blood pressure (sbp)
sort intervention sbp

// Step 3: Calculate the k-th and (1-k)-th percentiles for each group
* Control group percentiles
summarize sbp if intervention == 0, detail
scalar lower_control = r(p`k') // k-th percentile
scalar upper_control = r(p`=100-`k'') // (1-k)-th percentile
* Intervention group percentiles
summarize sbp if intervention == 1, detail
scalar lower_intervention = r(p`k') // k-th percentile
scalar upper_intervention = r(p`=100-`k'') // (1-k)-th percentile

// Step 4: Winsorize the sbp values
gen sbp_winsorized = sbp
// Winsorize control group
replace sbp_winsorized = lower_control if sbp < lower_control & intervention == 0 // Replace lower outliers
replace sbp_winsorized = upper_control if sbp > upper_control & intervention == 0 // Replace upper outliers
// Winsorize intervention group
replace sbp_winsorized = lower_intervention if sbp < lower_intervention & intervention == 1 // Replace lower outliers
replace sbp_winsorized = upper_intervention if sbp > upper_intervention & intervention == 1 // Replace upper outliers

// Step 5: Calculate the k-winsorized mean for each group
tabstat sbp_winsorized, by(intervention) s(n mean med sd sk)
graph box sbp_winsorized, by(intervention)
hist sbp_winsorized, by(intervention) norm


******Median 

use cohort_sbp,clear

***estimate the median and IQI
tabstat sbp, by(intervention) s(n med p25 p75 iqr)

***estimate the MAD
// Step 1: Calculate the median SBP for each group (control and intervention)
quietly summarize sbp if intervention == 0, detail
scalar median_control = r(p50) // Median SBP for control group

quietly summarize sbp if intervention == 1, detail
scalar median_intervention = r(p50) // Median SBP for intervention group

// Step 2: Generate variables for the absolute deviations from the median
gen abs_dev = abs(sbp - median_control) if intervention == 0
replace abs_dev = abs(sbp - median_intervention) if intervention == 1

// Step 3: Calculate the median absolute deviation (MAD) for each group
tabstat abs_dev, by(intervention) s(med)

//Alt: You may also use the egen command
egen mad=mad(sbp),by(intervention) // median absolute deviation from the median. Compared to the mean absolute deviation from the median, this seems to be better motivated, as a resistant version of what was long called "probable error" and as a quantity often expected to be close to IQR/2.


*****Robust hypothesis test
**comparing two-sample population medians
use cohort_sbp,clear

median sbp, by(intervention)
ranksum sbp, by(intervention)

**comparing several-sample population medians
use cohort_sbp,clear

kwallis sbp, by(intervention)


**************************************
// Practical session 2
use cohort_sbp,clear

// estimate the mean, median, k-trimmed mean, and k-winsorised mean and compare the results
tabstat sbp, by(intervention) s(n mean med sd sk)

//perform two-sample t test
ttest sbp, by(intervention)

// perform the median and rank-sum tests and compare results
median sbp, by(intervention)
ranksum sbp, by(intervention)



//Session 3: Median or LAD Regression

// The intuition behind OLS regression
*****
clear
set seed 12345 // For reproducibility

// Step 1: Generate data with 10 SBP observations and 2 outliers
set obs 10 // Create 10 observations
gen id = _n // Unique ID for each observation
gen age = 30 + 5*_n // Create age variable

// Generate systolic blood pressure (SBP) with two outliers
gen sbp = 120 + 0.5*age + rnormal(0, 40) // SBP as a function of age
replace sbp = sbp + 50 if id == 5 // Create an outlier
replace sbp = sbp - 40 if id == 9 // Create another outlier

// Step 2: Perform OLS regression 
reg sbp age
predict ols_reg, xb // Predict the values from the OLS regression

// Step 3: Plot the SBP observations, the median regression line, and deviations (errors)
twoway ///
    (scatter sbp age, msize(large) mcolor(blue)) /// Scatter plot of SBP vs age
    (line ols_reg age, lcolor(red)) /// OLS regression line
    (rcap sbp ols_reg age, lcolor(green)) /// Green vertical lines representing errors
    , ///
    title("OLS Regression with Deviations from Data Points") ///
    ylabel(100(50)300) ///
    xlabel(30(5)80) ///
	legend(order(1 "sbp" 2 "OLS regression line" 3 "residuals (r)"))
	

******** OLS: least squares function of the residuals
// Step 1: Simulate a dataset
clear
set seed 12345 // For reproducibility
set obs 100 // Generate 100 observations

// Generate independent variable (age)
gen age = round(runiform(30, 70)) // Random ages between 30 and 70

// Generate dependent variable (SBP: systolic blood pressure)
gen sbp = 120 + 0.5*age + rnormal(0, 10) // SBP depends on age with random noise

// Introduce some outliers
replace sbp = sbp + 50 if _n == 10 // High outlier
replace sbp = sbp - 40 if _n == 90 // Low outlier

// Step 2: Perform OLS regression
regress sbp age

// Step 3: Generate residuals
predict residuals, residuals

// Step 4: Calculate the standard deviation of residuals
summarize residuals
scalar sigma = r(sd) // Store the standard deviation of residuals

// Step 5: Transform residuals
gen residuals_in_sd = residuals / sigma // Residuals in standard deviation units
gen least_squares_function = residuals_in_sd^2 // Least squares function (r^2)

// Step 6: Plot the least squares function of the residuals
twoway (scatter least_squares_function residuals_in_sd, mcolor(blue)) ///
       (function y=x^2, range(-3 3) lcolor(red)), ///
       title("Least Squares Function of Residuals") ///
       xlabel(-3(1)3, grid) ///
       ylabel(0(1)10, grid) ///
       legend(order(1 "Residuals (data)" 2 "Least Squares Function (f(r) = r^2)")) ///
       xtitle("Residuals in Standard Deviation Units") ///
       ytitle("Least Squares Function (r^2)")


******************************
	
// The intuition behind Quantile (Median) regression

// Step 1: Load the systolic blood pressure dataset
use cohort_sbp.dta, clear

sum sbp, detail 
local mean_sbp = r(mean) //unconditional mean
local med_sbp = r(p50) //unconditional median

// Step 2: Run a regular OLS regression for comparison
regress sbp age
predict ols, xb // Predict OLS fitted values

// Step 3: Estimate quantile regressions at the 50th (median) percentile
qui qreg sbp age, quantile(0.50) // 50th percentile (median)
predict q50, xb // Predict fitted values for the 50th percentile

// Step 4: Plot the results
****mean plots
twoway scatter sbp age, yline(`mean_sbp') title("Unconditional mean") // unconditional mean

twoway (scatter sbp age) ///
       (line ols age, lcolor(black) lpattern(solid)) ///
       , ///
       title("OLS Regression: Conditional mean") ///
       xlabel(30(10)70) ///
       ylabel(100(20)160)

****median plots
twoway scatter sbp age, yline(`med_sbp') title("Unconditional median") // unconditional median

twoway (scatter sbp age) ///
       (line q50 age, lcolor(green) lpattern(solid)) ///
       , ///
       title("Median Regression: Conditional median") ///
       xlabel(30(10)70) ///
       ylabel(100(20)160)
	   

//The Intuition of Median Regression: Residuals
*****
clear
set seed 12345 // For reproducibility

// Step 1: Generate data with 10 SBP observations and 2 outliers
set obs 10 // Create 10 observations
gen id = _n // Unique ID for each observation
gen age = 30 + 5*_n // Create age variable

// Generate systolic blood pressure (SBP) with two outliers
gen sbp = 120 + 0.5*age + rnormal(0, 40) // SBP as a function of age
replace sbp = sbp + 50 if id == 5 // Create an outlier
replace sbp = sbp - 40 if id == 9 // Create another outlier

// Step 2: Perform median regression (quantile regression at the 50th percentile)
qreg sbp age, quantile(0.50)
predict med_reg, xb // Predict the values from the median regression

// Step 3: Plot the SBP observations, the median regression line, and deviations (errors)
twoway ///
    (scatter sbp age, msize(large) mcolor(blue)) /// Scatter plot of SBP vs age
    (line med_reg age, lcolor(red)) /// Median regression line
    (rcap sbp med_reg age, lcolor(green)) /// Green vertical lines representing errors
    , ///
    title("Median Regression with Deviations from Data Points") ///
    ylabel(100(50)300) ///
    xlabel(30(5)80) ///
	legend(order(1 "sbp" 2 "Median regression line" 3 "residuals"))
	

	
// Median or LAD regression weights the residuals linearly

// Step 1: Simulate a dataset
clear
set seed 12345 // For reproducibility
set obs 100 // Generate 100 observations

// Generate independent variable (age)
gen age = round(runiform(30, 70)) // Random ages between 30 and 70

// Generate dependent variable (SBP: systolic blood pressure)
gen sbp = 120 + 0.5*age + rnormal(0, 10) // SBP depends on age with random noise

// Introduce some outliers
replace sbp = sbp + 50 if _n == 10 // High outlier
replace sbp = sbp - 40 if _n == 90 // Low outlier

// Step 2: Perform OLS regression
regress sbp age

// Step 3: Generate residuals
predict residuals, residuals

// Step 4: Calculate the standard deviation of residuals
summarize residuals
scalar sigma = r(sd) // Store the standard deviation of residuals

// Step 5: Transform residuals
gen residuals_in_sd = residuals / sigma // Residuals in standard deviation units
gen lad_function = abs(residuals_in_sd) // Least Absolute Deviation function (|r|)

// Step 6: Plot the LAD function of the residuals
twoway (scatter lad_function residuals_in_sd, mcolor(blue)) ///
       (function y=abs(x), range(-3 3) lcolor(red)), ///
       title("Least Absolute Deviation (LAD) Function of Residuals") ///
       xlabel(-3(1)3, grid) ///
       ylabel(0(1)3, grid) ///
       legend(order(1 "Residuals (data)" 2 "LAD Function (f(r) = |r|)")) ///
       xtitle("Residuals in Standard Deviation Units") ///
       ytitle("LAD Function (|r|)")
	   
	   
	   
//Visual representation of median regresssion compared to OLS

// Step 1: Load the systolic blood pressure dataset
use cohort_sbp.dta, clear

// Step 2: Estimate quantile regressions at the 50th (median) percentile

qui qreg sbp age, quantile(0.50) // 50th percentile (median)
predict q50, xb // Predict fitted values for the 50th percentile

// Step 3: Run a regular OLS regression for comparison
regress sbp age
predict ols, xb // Predict OLS fitted values

// Step 4: Plot the results
twoway (scatter sbp age) ///
       (line q50 age, lcolor(blue) lpattern(dash)) ///
       (line ols age, lcolor(black) lpattern(solid)) ///
       , ///
       title("Median Regression vs OLS") ///
       legend(label(2 "Median Regression") label(3 "OLS Regression")) ///
       xlabel(30(10)70) ///
       ylabel(100(20)160)
	   

// Practical session 3: Median regression 

// Load the systolic blood pressure dataset
use cohort_sbp.dta, clear

**
xi: qreg sbp i.intervention age i.sex

xi: reg sbp i.intervention age i.sex





//Session 4: Robust regression	 


// The intuition of robust regression: Huber's M-Estimator

// Step 1: Simulate a dataset
clear
set seed 12345 // For reproducibility
set obs 100 // Generate 100 observations

// Generate independent variable (age)
gen age = round(runiform(30, 70)) // Random ages between 30 and 70

// Generate dependent variable (SBP: systolic blood pressure)
gen sbp = 120 + 0.5*age + rnormal(0, 10) // SBP depends on age with random noise

// Introduce some outliers
replace sbp = sbp + 50 if _n == 10 // High outlier
replace sbp = sbp - 40 if _n == 90 // Low outlier

// Step 2: Perform OLS regression
regress sbp age

// Step 3: Generate residuals
predict residuals, residuals

// Step 4: Calculate the standard deviation of residuals
summarize residuals
scalar sigma = r(sd) // Store the standard deviation of residuals

// Step 5: Transform residuals
gen residuals_in_sd = residuals / sigma // Residuals in standard deviation units
gen least_squares_function = residuals_in_sd^2 // Least Squares function (r^2)
gen lad_function = abs(residuals_in_sd) // Least Absolute Deviation function (|r|)

// Define the threshold parameter delta
local delta 1 // delta is at or around the intersection of OLS and LAD functions

// Step 6: Plot both the least squares and LAD functions with vertical dotted lines
twoway ///
    (scatter least_squares_function residuals_in_sd, mcolor(blue) msize(small)) /// Scatter for least squares
    (function y=x^2, range(-3 3) lcolor(blue) lpattern(solid)) /// Least squares function (r^2)
    (scatter lad_function residuals_in_sd, mcolor(red) msize(small)) /// Scatter for LAD
    (function y=abs(x), range(-3 3) lcolor(red) lpattern(dash)), /// LAD function (|r|)
    xline(`delta', lcolor(green) lpattern(dash) lwidth(0.5)) /// Vertical line at +delta
    xline(-`delta', lcolor(green) lpattern(dash) lwidth(0.5)) /// Vertical line at -delta
    title("Least Squares and LAD Functions of Residuals") ///
    xlabel(-3(1)3, grid) ///
    ylabel(0(1)10, grid) ///
    legend(order(1 "Least Squares (r^2) data" 2 "Least Squares Function" ///
                 3 "LAD (|r|) data" 4 "LAD Function" 5 "Threshold (delta)")) ///
    xtitle("Residuals in Standard Deviation Units") ///
    ytitle("Functions of Residuals")
	

// The intuition of robust regression: Huber's M-Estimator

// Step 1: Define a range of residuals
clear
set obs 100 // Create 100 observations
gen r = -3 + 0.06 * (_n - 1) // Generate residuals from -3 to 3

// Step 2: Define the tuning constant (delta)
local delta 1.5 // Tuning constant for Huber's function

// Step 3: Compute the Huber M-estimator objective function
gen huber = ///
    cond(abs(r) <= `delta', ///
    r^2, /// Quadratic for small residuals
    2 * `delta' * abs(r) - `delta'^2) /// Linear for large residuals

// Step 4: Plot the Huber M-estimator objective function
twoway (line huber r, lcolor(blue) lpattern(solid)), ///
    title("Objective Function of Huber's M-Estimator") ///
    xlabel(-3(1)3, grid) ///
    ylabel(, angle(horizontal)) ///
    xtitle("Residuals (r)") ///
    ytitle("Huber Objective Function (\u03c1(r))") ///
    legend(off)	

	
//The intuition of robust regression: Biweight M-Estimator
	
// Step 1: Define a range of residuals
clear
set obs 100 // Create 100 observations
gen r = -3 + 0.06 * (_n - 1) // Generate residuals from -3 to 3

// Step 2: Define the tuning constant (c)
local c 1.5 // Tuning constant for biweight function

// Step 3: Compute the biweight objective function
gen biweight = ///
    cond(abs(r) <= `c', ///
    `c'^2 * (1 - (1 - (r/`c')^2)^3), ///
    `c'^2)

// Step 4: Plot the biweight objective function
twoway (line biweight r, lcolor(blue) lpattern(solid)), ///
    title("Objective Function of Biweight M-Estimator") ///
    xlabel(-3(1)3) ///
    ylabel(, angle(horizontal)) ///
    xtitle("Residuals (r)") ///
    ytitle("Biweight Objective Function (\u03c1(r))") ///
    legend(off)	
	
	
	
//The intuition of robust regression
	
// Step 1: Define a range of residuals
clear
set obs 100
gen r = -3 + 0.06 * (_n - 1) // Generate residuals from -3 to 3

// Step 2: Define tuning constants
local delta 1.5 // Tuning constant for Huber's M-estimator
local c 1.5     // Tuning constant for Biweight estimator

// Step 3: Compute the functions
// OLS function: r^2
gen ols = r^2

// LAD function: |r|
gen lad = abs(r)

// Huber's M-estimator
gen huber = cond(abs(r) <= `delta', r^2, 2 * `delta' * abs(r) - `delta'^2)

// Biweight estimator
gen biweight = cond(abs(r) <= `c', ///
    `c'^2 * (1 - (1 - (r/`c')^2)^3), ///
    `c'^2)

// Step 4: Plot all functions on the same graph
twoway ///
    (line ols r, lcolor(blue) lpattern(solid) lwidth(medium)) /// OLS function
    (line lad r, lcolor(red) lpattern(dash) lwidth(medium)) /// LAD function
    (line huber r, lcolor(green) lpattern(dash_dot) lwidth(thick)) /// Huber's M-estimator
    (line biweight r, lcolor(black) lpattern(longdash) lwidth(thick)), /// Biweight estimator
    title("Comparison of Robust Regression Functions") ///
	xline(1, lcolor(green) lpattern(dash) lwidth(0.5)) /// Vertical line at +delta
    xline(-1, lcolor(green) lpattern(dash) lwidth(0.5)) /// Vertical line at -delta
    xlabel(-3(1)3) ///
    ylabel(0(1)10, grid) ///
    legend(order(1 "OLS (r^2)" 2 "LAD (|r|)" 3 "Huber's M-estimator" 4 "Biweight Estimator")) ///
    xtitle("Residuals (r)") ///
    ytitle("Objective Function (\u03c1(r))")
	
	
******
use cohort_sbp.dta, clear
**
xi: reg sbp i.intervention age i.sex // we begin running OLS and perform some diagnostics

**
lvr2plot

**
predict d1, cooksd
list sbp intervention age sex d1 if d1>4/100, noobs

**
predict r1, rstandard
gen absr1 = abs(r1)
gsort -absr1
list sbp absr1 in 1/10, noobs

**
xi: rreg sbp i.intervention age i.sex, gen(weight)

**
list id intervention age sex sbp d1 r1 absr1 _Iintervent_1 _Isex_1 weight in 1/10, noobs

**
sort weight
list sbp d1 r1 absr1 weight in 1/10, noobs



** visualisation of OLS and Rebust Regression

// Step 1: Load the cohort_sbp dataset
use cohort_sbp.dta, clear

// Step 2: Perform OLS regression (Ordinary Least Squares)
regress sbp age

// Predict the OLS fitted values
predict ols_pred, xb

// Step 3: Perform Robust Regression
rreg sbp age

// Predict the robust regression fitted values
predict robust_pred, xb

// Step 4: Scatter plot of SBP vs Age, with both OLS and Robust regression lines
twoway ///
    (scatter sbp age, msize(medium) mcolor(blue)) /// Scatter plot of the actual data points
    (line ols_pred age, lcolor(red) lpattern(solid)) /// OLS regression line (solid red)
    (line robust_pred age, lcolor(green) lpattern(dash)) /// Robust regression line (dashed green)
    , ///
    title("OLS vs Robust Regression on SBP Data") ///
    ylabel(100(20)200) ///
    xlabel(30(5)70) ///
    legend(order(1 "SBP data" 2 "OLS Regression Line" 3 "Robust Regression Line"))
	
	
*Practical session 4 : Robust Regression

use cohort_sbp.dta, clear
**
xi: reg sbp i.intervention age i.sex // we begin running OLS and perform some diagnostics

**
lvr2plot

xi: rreg sbp i.intervention age i.sex, gen(weight)




**************************************************
*Practical - Diagnotics and Analytics Workflow
**************************************************

*******************************************************
* Simulate binary HTN control data with:
*  (i) high-leverage X points (extreme covariates)
*  (ii) "outliers" in binary sense (y discordant with p̂)
* Then diagnose + choose a sensible handling strategy.
* Stata 19 (plain logit)
*******************************************************

clear all
set more off
set seed 26022026

***************************************
* 1) SIMULATE A REALISTIC STUDY SETUP
***************************************
* Example: lifestyle intervention effect on hypertension control (yes/no)
* Outcome: control = 1 if BP controlled at follow-up
* Predictors: intervention, age, sex, BMI, baseline SBP, diabetes

set obs 800
gen long id = _n

* Core covariates
gen byte intervention = (runiform() < 0.50)                 // randomized
gen byte female       = (runiform() < 0.55)
gen double age        = rnormal(48, 12)
replace age = max(18, min(age, 85))

gen double bmi        = rnormal(28, 5)
replace bmi = max(16, min(bmi, 55))

gen byte diabetes     = (runiform() < invlogit(-2 + 0.04*(age-50) + 0.07*(bmi-28)))

* Baseline SBP (correlated with age, bmi, diabetes)
gen double sbp0 = rnormal(150 + 0.35*(age-50) + 0.9*(bmi-28) + 7*diabetes, 12)

* TRUE data-generating model for control (higher = more likely controlled)
* Lifestyle intervention improves control; older age, higher BMI, higher baseline SBP, diabetes reduce control
gen double xb_true = ///
    0.50*intervention ///
  - 0.03*(age-50) ///
  - 0.05*(bmi-28) ///
  - 0.04*((sbp0-150)/10) ///
  - 0.60*diabetes ///
  + 0.15*female

gen double p_true = invlogit(xb_true)
gen byte control  = (runiform() < p_true)
label define yn 0 "No" 1 "Yes"
label values control yn
label values intervention yn
label values female yn
label values diabetes yn

***************************************
* 2) INJECT HIGH-LEVERAGE OBSERVATIONS
***************************************
* Create a small set of extreme covariate patterns (unusual X rows)
* These points can pull estimates even if y isn't "wrong".

gen byte leverage = 0
local L = 10
forvalues j = 1/`L' {
    local i = 790 + `j'   // last 10 ids
    replace leverage = 1 in `i'
}

* Make them extreme in X-space
replace age  = 85     if leverage
replace bmi  = 48     if leverage
replace sbp0 = 220    if leverage
replace diabetes = 1  if leverage
replace female   = (runiform()<0.3) if leverage

* Recompute true probability for these (so their x is extreme but model-consistent)
replace xb_true = ///
    0.50*intervention ///
  - 0.03*(age-50) ///
  - 0.05*(bmi-28) ///
  - 0.04*((sbp0-150)/10) ///
  - 0.60*diabetes ///
  + 0.15*female if leverage
replace p_true = invlogit(xb_true) if leverage
replace control = (runiform() < p_true) if leverage

***************************************
* 3) INJECT "BINARY OUTLIERS" (DISCORDANT y)
***************************************
* "Outlier" in logistic sense = p̂ extreme but observed y opposite.
* We flip outcomes for a few extreme predicted probabilities.

* Identify cases with very high/low true p
gen byte cand_hi = (p_true > 0.97)
gen byte cand_lo = (p_true < 0.03)

* Flip 8 high-prob successes into failures and 8 low-prob failures into successes
gen double u = runiform()
sort u
gen byte flip = 0
replace flip = 1 if cand_hi & _n<=8
replace flip = 1 if cand_lo & _n>8 & _n<=16
replace control = 1-control if flip

drop u cand_hi cand_lo

sort id

save hypothetical_study,replace






*******************************************************
* Diagnostic workflow for CONTINUOUS outcome (OLS)
* Example: systolic blood pressure (sbp)
* Stata 19
*******************************************************

use hypothetical_study, clear
set more off

*------------------------------------------------------*
* 0) Fit OLS for DIAGNOSTICS (must be non-robust)
*------------------------------------------------------*
regress sbp i.intervention c.age c.bmi i.female i.diabetes
est store M_ols

* Save p and n for cutoffs
local p = e(df_m) + 1
local n = e(N)

*------------------------------------------------------*
* 1) Core predictions & residuals (from non-robust OLS)
*------------------------------------------------------*
predict double yhat, xb
predict double e, resid

* Studentized residuals (allowed after non-robust OLS)
predict double rstud, rstudent      // externally studentized
predict double rint,  rstandard     // internally studentized

*------------------------------------------------------*
* 2) OUTLIERS in Y-space (large residuals)
*------------------------------------------------------*
* Rule-of-thumb cutoffs:
* |externally studentized residual| > 2 (flag), > 3 (strong)
gen byte out2 = (abs(rstud) > 2)
gen byte out3 = (abs(rstud) > 3)

* Also flag large raw residuals relative to residual SD
quietly summarize e, detail
gen byte out_e3sd = (abs(e) > 3*r(sd))

*------------------------------------------------------*
* 3) HIGH LEVERAGE points (unusual X-space)
*------------------------------------------------------*
* Common leverage cutoffs: > 2p/n or > 3p/n, where p = #parameters incl intercept
predict double hat, hat

local lev2 = 2*`p'/`n'
local lev3 = 3*`p'/`n'
gen byte lev_hi2 = (hat > `lev2')
gen byte lev_hi3 = (hat > `lev3')

*------------------------------------------------------*
* 4) INFLUENCE points (impact on coefficients)
*------------------------------------------------------*
* Cook's D
predict double cookd, cooksd
gen byte infl_cook  = (cookd > 4/`n') // common rule-of-thumb
gen byte infl_cook1 = (cookd > 1) // strong influence (rare in large n)


* DFBETAs (one-by-one; intercept excluded)
predict double dfb_intervention, dfbeta(intervention)
predict double dfb_age,          dfbeta(age)
predict double dfb_bmi,          dfbeta(bmi)
predict double dfb_female,       dfbeta(1.female)
predict double dfb_diabetes,     dfbeta(1.diabetes)

local dfbcut = 2/sqrt(`n')

* max |DFBETA| (egen rowmax needs variable names, not abs())
foreach v in dfb_intervention dfb_age dfb_bmi dfb_female dfb_diabetes {
    gen double abs_`v' = abs(`v')
}
egen double maxabsdfb = rowmax(abs_dfb_intervention abs_dfb_age abs_dfb_bmi abs_dfb_female abs_dfb_diabetes)
drop abs_dfb_intervention abs_dfb_age abs_dfb_bmi abs_dfb_female abs_dfb_diabetes

gen byte infl_dfb = (maxabsdfb > `dfbcut')

* DFITS (NOTE: option name is dfits, not dffits)
predict double dfits, dfits
gen byte infl_dfits = (abs(dfits) > 2*sqrt(`p'/`n'))

* COVRATIO
predict double covrat, covratio
gen byte infl_covr = (covrat < 1 - 3*`p'/`n' | covrat > 1 + 3*`p'/`n')

* Combined flag
gen byte flag_any = out2 | lev_hi3 | infl_cook | infl_dfb | infl_dfits | infl_covr

di as txt "Cutoffs:"
di as txt "  leverage > 3p/n = " %6.4f `lev3'
di as txt "  max|DFBETA| > 2/sqrt(n) = " %6.4f `dfbcut'
di as txt "  CookD > 4/n = " %6.4f (4/`n')
di as txt "  |DFITS| > 2*sqrt(p/n) = " %6.4f (2*sqrt(`p'/`n'))

*------------------------------------------------------*
* 5) Summaries and listings
*------------------------------------------------------*
tab out2 out3
tab lev_hi3
tab infl_cook infl_dfb
tab infl_dfits infl_covr
tab flag_any

gsort -cookd
list sbp yhat e rstud hat cookd dfits maxabsdfb ///
     intervention age bmi female diabetes ///
     in 1/25, abbrev(20)

list sbp yhat e rstud hat cookd dfits maxabsdfb ///
     intervention age bmi female diabetes ///
     if flag_any, abbrev(20)

*------------------------------------------------------*
* 6) Graphical diagnostics (core OLS plots)
*------------------------------------------------------*
* Residuals vs fitted (nonlinearity / heteroskedasticity)
rvfplot, yline(0)

* Added-variable (partial regression) plots: check linearity & leverage per predictor
avplots

* Normal Q-Q plot of residuals (normality of errors; mainly for small-sample inference)
qnorm e

* Leverage vs squared residuals (visual influence diagnostic)
lvr2plot

*------------------------------------------------------*
* 7) Assumption / specification checks
*------------------------------------------------------*
* Heteroskedasticity tests (still useful even if you use robust SEs)
estat hettest
estat imtest, white

* Omitted variables / functional form (Ramsey RESET)
estat ovtest

* Multicollinearity screening
estat vif

*------------------------------------------------------*
* 8) PRIMARY INFERENCE MODEL (robust SEs)
*------------------------------------------------------*
regress sbp intervention c.age c.bmi i.female i.diabetes, vce(robust)
est store M_ols_rob

* Robust regression alternative (downweights outliers)
rreg sbp intervention c.age c.bmi i.female i.diabetes
est store M_rreg

* Sensitivity excluding flagged points (analogous to trimmed mean)
regress sbp intervention c.age c.bmi i.female i.diabetes if !flag_any, vce(robust)
est store M_drop 

estimates table M_ols_rob M_rreg M_drop, b(%9.3f) se(%9.3f) stats(N r2 rmse)


/*
//Note: This pattern suggests our "flag_any" rule is very aggressive (dropping ~20% of the dataset), and that the intervention estimate is somewhat sensitive to those flags. That doesn't automatically mean "the intervention effect is fragile"—it often means the flag definition is catching many points that are not truly problematic

What I would do next (practical refinement)

If you want the sensitivity analysis to be more surgical, tighten the flagging rule. For example:
	- Use out3 instead of out2: abs(rstud)>3
	- Keep lev_hi3 (hat > 3p/n)
	- Keep infl_cook but consider a stricter cutoff (e.g., CookD > 4/n is fine; for large n you may also look at top-K)
	- Keep infl_dfits (often a good single summary)

Example "less aggressive" flag:

Note: avoid deletion as primary unless you can justify data errors
*/
gen byte flag_any2 = out3 | lev_hi3 | infl_dfits

regress sbp intervention c.age c.bmi i.female i.diabetes if !flag_any2, vce(robust)
est store M_drop_v1

estimates table M_ols_rob M_drop M_drop_v1 M_rreg, b(%9.3f) se(%9.3f) stats(N r2 rmse)

/*
// Reporting : OLS with robust (Huber–White) standard errors as the primary inference model is the right default given the diagnostics for heteroskedasticity. But add two important caveats based on what we've shown:

1) Robust SEs should be primary for inference here

Both hettest and imtest, white reject homoskedasticity (p=0.0001 and p=0.0046). That means classical OLS SEs are not trustworthy, so our primary inferential model should be:
*/
regress sbp intervention c.age c.bmi i.female i.diabetes, vce(robust) //This keeps the same coefficients as OLS but gives valid standard errors under heteroskedasticity.

/* 2) Our bigger issue is not SEs — it's functional form (RESET)

estat ovtest is strongly significant. That suggests model misspecification (often nonlinearity and/or missing interactions). Robust SEs do not fix bias from a wrong mean model; they only fix inference about that (possibly misspecified) mean model.

So I'd frame our analysis plan as:
	- Primary model: OLS mean model + robust SEs
	- Key sensitivity: address mean-model misspecification (splines/nonlinear terms) and influence (robust regression)
	
Note: rreg is useful, but I would not make it primary by default because:
	- it targets outlier-resistant estimation, not heteroskedasticity per se,
	- its SEs and objective differ from OLS (so the estimand shifts),
	- reviewers often prefer OLS+robust SE as the mainline approach unless contamination/outliers are a core feature.
*/




*******************************************************
* Diagnostics + analytic workflow for BINARY outcome (LOGIT + RR)
* Outcome: control (0/1), e.g., hypertension control
* Primary: Adjusted RR via modified Poisson (robust SE)
* Sensitivity: (A) RR model excluding flagged points
*              (B) Marginal (standardized) RR from logistic model
*                  (report lnmRR and exponentiate for RR/CI)
* Stata 19
*******************************************************

use hypothetical_study, clear
set more off

*------------------------------------------------------*
* 0) Fit LOGIT (MLE) for diagnostics
*------------------------------------------------------*
logit control i.intervention c.age c.bmi c.sbp0 i.female i.diabetes
est store M_logit

*------------------------------------------------------*
* 1) Predictions and core residuals / influence stats
*------------------------------------------------------*
predict double phat, pr
predict double xb, xb
predict double rdev, deviance
predict double rpea, residuals
predict double rstd, rstandard
predict double hat, hat
predict double dbeta, dbeta
predict double dx2,   dx2
predict double dd,    ddeviance

*------------------------------------------------------*
* 2) Flags (outliers, leverage, influence)
*------------------------------------------------------*
gen byte rare0 = (control==0 & phat>0.95)
gen byte rare1 = (control==1 & phat<0.05)

gen byte out_dev2  = (abs(rdev) > 2)
gen byte out_dev3  = (abs(rdev) > 3)
gen byte out_rstd2 = (abs(rstd) > 2)
gen byte out_rstd3 = (abs(rstd) > 3)

local p = e(df_m) + 1
local n = e(N)
local lev2 = 2*`p'/`n'
local lev3 = 3*`p'/`n'

gen byte lev_hi2 = (hat > `lev2')
gen byte lev_hi3 = (hat > `lev3')

quietly summarize dbeta, detail
gen byte infl_dbeta = (abs(dbeta) > r(p99))

quietly summarize dx2, detail
gen byte infl_dx2   = (dx2 > r(p99))

quietly summarize dd, detail
gen byte infl_dd    = (dd > r(p99))

gen byte flag_any = rare0 | rare1 | out_dev3 | lev_hi3 | infl_dbeta | infl_dx2 | infl_dd

*------------------------------------------------------*
* 3) Summaries / listings (optional)
*------------------------------------------------------*
di as txt "Cutoffs: leverage>3p/n=" %6.4f `lev3'
tab rare0 rare1
tab out_dev2 out_dev3
tab out_rstd2 out_rstd3
tab lev_hi3
tab infl_dbeta infl_dx2
tab flag_any

gsort -hat
list control phat rdev rstd hat dbeta dx2 dd ///
     intervention age bmi sbp0 female diabetes ///
     in 1/20, abbrev(20)

gsort -dx2
list control phat rdev rstd hat dbeta dx2 dd ///
     intervention age bmi sbp0 female diabetes ///
     in 1/20, abbrev(20)

list control phat rdev rstd hat dbeta dx2 dd ///
     intervention age bmi sbp0 female diabetes ///
     if flag_any, abbrev(20)

*------------------------------------------------------*
* 4) PRIMARY INFERENCE MODEL: Adjusted RR
*    Modified Poisson + robust SEs
*------------------------------------------------------*
poisson control i.intervention c.age c.bmi c.sbp0 i.female i.diabetes, vce(robust)
est store M_rr_rob

* Display adjusted RRs (IRR label; interpret as RR)
est restore M_rr_rob
poisson, irr

* RR for intervention (with CI)
lincom 1.intervention, eform

*------------------------------------------------------*
* 5) Sensitivity analyses
*   (A) RR model excluding flagged points
*   (B) Marginal (standardized) RR from LOGIT:
*       compute lnmRR and exponentiate for RR/CI/p
*------------------------------------------------------*

* (A) Sensitivity RR model (drop flagged)
poisson control i.intervention c.age c.bmi c.sbp0 i.female i.diabetes if !flag_any, vce(robust)
est store M_rr_drop

est restore M_rr_drop
poisson, irr
lincom 1.intervention, eform

* (B) Marginal RR from LOGIT (standardized over covariate distribution)
logit control i.intervention c.age c.bmi c.sbp0 i.female i.diabetes, vce(robust)
est store M_logit_rob

* Standardized risks at intervention=0 and 1; POST so nlcom can use them
margins, at(intervention=(0 1)) predict(pr) post

* Log marginal RR (use this for inference)
nlcom (lnmRR: ln(_b[2._at]) - ln(_b[1._at]))

* ---- Pretty print RR, 95% CI, and p-value from lnmRR ----
tempname T
matrix `T' = r(table)

scalar lnmRR = `T'[1,1]
scalar se    = `T'[2,1]
scalar pval  = `T'[4,1]
scalar lb    = lnmRR - invnormal(0.975)*se
scalar ub    = lnmRR + invnormal(0.975)*se

di as txt "Marginal RR (standardized): " ///
   %6.3f exp(lnmRR) "  [95% CI " %6.3f exp(lb) ", " %6.3f exp(ub) "], p=" %6.4f pval

* (Optional) Marginal RD too (risk difference)
nlcom (mRD: _b[2._at] - _b[1._at])

*------------------------------------------------------*
* 6) Compact comparison table (primary RR + sensitivity RR)
*------------------------------------------------------*
estimates table M_rr_rob M_rr_drop, b(%9.3f) se(%9.3f) stats(N)

*******************************************************
* End
*******************************************************
















	
	