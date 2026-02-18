//Import data
use "C:\Users\akojo\OneDrive\Documents\Framingham_practices.dta"

//recode education variable into "uneducated" and "educated"
tab educ
tab educ, nolab
recode educ (1=1 "uneducated") (2 3 4=2 "educated"), gen(edu_formal)
tab edu_formal

//Descriptive Statistics

*Estimate mean and standard deviation for bmi
sum bmi 

sum bmi, detail 

*Estimate mean and standard deviation for bmi, age and sysbp
sum bmi age sysbp

sum bmi age sysbp, detail

*Estimate the mean and standard deviation of bmi among smokers
bys cursmoke: sum bmi

*Estimate the mean and standard deviation of bmi, age and sysbp among smokers
bys cursmoke: sum bmi age sysbp

*Estimating additional statistics using tabstat
help tabstat
tabstat bmi
tabstat bmi, stat(mean semean sd var cv iqr q skewness kurtosis)
tabstat bmi age sysbp, stat(mean semean sd var cv iqr q skewness kurtosis)
tabstat bmi, stat(mean semean sd var cv iqr q skewness kurtosis) by(cursmoke)
tabstat bmi, stat(mean semean sd var cv iqr q skewness kurtosis) by(sex)
tabstat bmi age sysbp, stat(mean semean sd var cv iqr q skewness kurtosis) by(cursmoke)
tabstat bmi age sysbp, stat(mean semean sd var cv iqr q skewness kurtosis) by(cursmoke) long

*Estimating confidence interval for the mean
ci mean bmi
ci mean bmi, level(99)
ci mean bmi, level(90)
bys sex: ci mean bmi, level(99)

*Estimating frequencies
tab death
tab1 cursmoke cvd death sex

*Crosstabulations
tab cursmoke death

tab cursmoke death, row
tab cursmoke death, col
tab cursmoke death, col row
