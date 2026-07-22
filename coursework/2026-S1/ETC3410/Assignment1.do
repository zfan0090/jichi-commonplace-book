* Reset
clear all

* Set working directory
cd "C:\Users\Matilda Fang\Desktop\2026 S1\ETC3410\Assignment\stata"

* Create a log file
capture log close
log using "Assignment1.log", replace

use grogger.dta,clear

*Question 1.1(a)
gen parr86 = (nparr86 > 0)
label variable parr86 "Arrested for property crime in 1986"

*Question 1.1(b)
summarize parr86

*Question 1.1(c)
* i) Proportion Black
summarize black if parr86 == 1

* ii) Proportion Hispanic
summarize hispan if parr86 == 1

* iii) Proportion born in 1960
summarize born60 if parr86 == 1

*Question 1.1(d)
summarize pcnv if parr86 == 1
summarize pcnv if parr86 == 0


* Question 1.2(a): Linear Probability Model
reg parr86 pcnv, robust


* Question 1.2(c)
logit parr86 pcnv


* Question 1.2(d)
reg parr86 pcnv pcnvsq avgsen tottime ptime86 qemp86 inc86 black hispan born60, robust
gen me_pcnv = _b[pcnv] + 2*_b[pcnvsq]*pcnv
sum me_pcnv

reg parr86 c.pcnv##c.pcnv avgsen tottime ptime86 qemp86 inc86 black hispan born60, robust
margins, dydx(pcnv)

* Question 1.2(e)
logit parr86 c.pcnv##c.pcnv avgsen tottime ptime86 qemp86 inc86 black hispan born60
margins, dydx(pcnv)

* Question 1.2(f)
* (i) LPM in part (d)
reg parr86 pcnv pcnvsq avgsen tottime ptime86 qemp86 inc86 black hispan born60, robust
display _b[pcnv]*(0.25-0.20) + _b[pcnvsq]*(0.25^2-0.20^2)

* (ii) Logit in part (e)
logit parr86 c.pcnv##c.pcnv avgsen tottime ptime86 qemp86 inc86 black hispan born60

margins, atmeans ///
    at(pcnv=0.20 hispan=1 born60=1) ///
    at(pcnv=0.25 hispan=1 born60=1) post

lincom _b[2._at] - _b[1._at]

* (iii) AME of being black
logit parr86 c.pcnv##c.pcnv avgsen tottime ptime86 qemp86 inc86 black hispan born60
margins, dydx(black)


* Question 1.2(g)
* Unrestricted model: same as part (e)
logit parr86 c.pcnv##c.pcnv avgsen tottime ptime86 qemp86 inc86 black hispan born60
est store unrestricted

* Restricted model: impose avgsen = 0, tottime = 0, inc86 = 0
logit parr86 c.pcnv##c.pcnv ptime86 qemp86 black hispan born60
est store restricted

* Likelihood-ratio test
lrtest restricted unrestricted

