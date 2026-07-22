* Reset
clear all
set more off

* Set working directory
cd "C:\Users\Matilda Fang\Desktop\2026 S1\ETC3410\Assignment 2"

* Create a log file
capture log close
log using "Assignment 2.log", replace text

* Load data
use VOUCHER.dta, clear

* Check key variables
describe selectyrs choiceyrs mnce94
summarize selectyrs choiceyrs mnce94

* Question 3.1
*(a): Students never awarded a voucher
count if selectyrs == 0

*(b): Students with voucher available for four years
count if selectyrs == 4

*(c): Students attending a choice school for four years
count if choiceyrs == 4

tab selectyrs
tab choiceyrs


* Question 3.2
*(a): First-stage regression
reg choiceyrs selectyrs

* Export the regression result using outreg2
outreg2 using "Q3_results.doc", replace ctitle("First-stage regression") ///
    dec(3) se

* (b): Instrument relevance test
* H0: coefficient on selectyrs = 0
* H1: coefficient on selectyrs != 0
test selectyrs


* Question 3.3:
* (a): 
reg mnce94 choiceyrs
outreg2 using "Q3_OLS_results.doc", replace ctitle("OLS Simple") ///
    dec(3) se

*(b)
reg mnce94 choiceyrs black hispanic female
outreg2 using "Q3_OLS_results.doc", append ctitle("OLS Controls") ///
    dec(3) se
	
	
* Question 3.5	
* 3.5(a)
reg mnce94 choiceyrs black hispanic female

outreg2 using "Q3_IV_results.doc", replace ctitle("OLS") ///
    dec(3) se

* (a): IV regression
ivregress 2sls mnce94 black hispanic female (choiceyrs = selectyrs)

outreg2 using "Q3_IV_results.doc", append ctitle("IV") ///
    dec(3) se

*(b): Test significance of choiceyrs in the IV regression
* H0: coefficient on choiceyrs = 0
* H1: coefficient on choiceyrs != 0
test choiceyrs



* Question 3.6
* 3.6(a): OLS with mnce90
reg mnce94 choiceyrs black hispanic female mnce90

outreg2 using "Q3_6_results.doc", replace ctitle("OLS with mnce90") ///
    dec(3) se

* 3.6(a): IV with mnce90
ivregress 2sls mnce94 black hispanic female mnce90 ///
    (choiceyrs = selectyrs)

outreg2 using "Q3_6_results.doc", append ctitle("IV with mnce90") ///
    dec(3) se

* 3.6(b): Sample size before adding mnce90
reg mnce94 choiceyrs black hispanic female

* 3.6(b): Sample size after adding mnce90
reg mnce94 choiceyrs black hispanic female mnce90


* Question 3.7
* 3.7(a): Test exogeneity of choiceyrs using selectyrs dummies as IVs
* First-stage regression
reg choiceyrs selectyrs1 selectyrs2 selectyrs3 selectyrs4 ///
    black hispanic female mnce90

outreg2 using "Q3_7a_endogeneity_test.doc", replace ///
    ctitle("First stage") dec(3) se

* Generate first-stage residual
capture drop vhat
predict vhat, residual

* Augmented structural equation
reg mnce94 choiceyrs black hispanic female mnce90 vhat

outreg2 using "Q3_7a_endogeneity_test.doc", append ///
    ctitle("Augmented equation") dec(3) se

* Test exogeneity of choiceyrs
* H0: coefficient on vhat = 0, choiceyrs is exogenous
* H1: coefficient on vhat != 0, choiceyrs is endogenous
test vhat

* 3.7(b): 2SLS using selectyrs1-selectyrs4 as instruments
ivregress 2sls mnce94 black hispanic female ///
    (choiceyrs = selectyrs1 selectyrs2 selectyrs3 selectyrs4)

outreg2 using "Q3_7b_2SLS_dummy_IVs.doc", replace ///
    ctitle("IV with dummy instruments") dec(3) se


* 3.7(b): 2SLS using selectyrs1-selectyrs4 as instruments
ivregress 2sls mnce94 black hispanic female ///
    (choiceyrs = selectyrs1 selectyrs2 selectyrs3 selectyrs4)

outreg2 using "Q3_7_results.doc", replace ctitle("IV with dummy instruments") ///
    dec(3) se
	
* 3.8: 2SLS using four selectyrs dummy instruments
ivregress 2sls mnce94 black hispanic female ///
    (choiceyrs = selectyrs1 selectyrs2 selectyrs3 selectyrs4)

* Obtain IV residuals
capture drop uhat
predict uhat, residuals

* Auxiliary regression for overidentification test
reg uhat black hispanic female selectyrs1 selectyrs2 selectyrs3 selectyrs4

* Calculate LM = nR^2
scalar LM = e(N)*e(r2)
scalar df = 4 - 1
scalar crit = invchi2(df, 0.95)
scalar pval = chi2tail(df, LM)


*Question 4
use "rhc.dta", clear

* ii) 
count 
tabulate rhc
sum rhc

* iii) 
reg death i.rhc, robust
outreg2 using "Q4_iii_OLS.doc", replace ctitle("OLS Baseline") dec(3) se

* iv) (SRA)
teffects ra (death age i.sex i.race i.income i.cat1 i.cat2 i.ninsclas) (rhc), atet
outreg2 using "Q4_iv_RA.doc", replace ctitle("RA Model") dec(3) se

* v) 
logit rhc age i.sex i.race i.income i.cat1 i.cat2 i.ninsclas
outreg2 using "Q4_v_Logit.doc", replace ctitle("Propensity Score Logit") dec(3) se

predict ps, pr

summ ps if rhc==1, detail
summ ps if rhc==0, detail

* Histograms of propensity scores
histogram ps if rhc == 1, ///
    title("Propensity scores: Treated") ///
    xtitle("Estimated propensity score") ///
    ytitle("Frequency") name(ps_treated, replace)

graph export "Q4_v_pscore_treated.png", replace
histogram ps if rhc == 0, ///
    title("Propensity scores: Untreated") ///
    xtitle("Estimated propensity score") ///
    ytitle("Frequency") name(ps_untreated, replace)

* vi) (IPW)
teffects ipw (death) (rhc age i.sex i.race i.income i.cat1 i.cat2 i.ninsclas, logit), atet
outreg2 using "Q4_vi_IPW.doc", replace ctitle("IPW Model") dec(3) se

log close

