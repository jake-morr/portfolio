capture log close
log using 6073_regressions.log, replace
set linesize 255
set more off
set varabbrev off

clear all
use regressions.dta

replace post = post / 1000

replace sex = 0 if sex == 2

replace marst = 1 if marst == 1 | marst == 2
replace marst = 0 if marst >= 3

* Baseline no controls *

reg commute post i.msa i.year if inctot_2019 > 184000, cluster(msa)

* Baseline with controls *

reg commute post inctot_2019 sex age labforce_partic racesing marst i.msa i.year, cluster(msa)

* Baseline with time specific linear time trends

reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year i.msa#c.year, cluster(msa)

* Baseline with Move as dependent and controls *

reg move post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year, cluster(msa)

* Baseline with Female Labor Force Participation as dependent and controls *

reg labforce_partic post sex inctot_2019 age occ racesing marst i.msa i.year, cluster(msa)

reg labforce_partic post inctot_2019 age occ racesing marst i.msa i.year if sex == 0, cluster(msa)

* Baseline with controls, income distribution *

*0-25th*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 <= 22000, cluster(msa)
*26-50*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 22000 & inctot_2019 <= 40100, cluster(msa)
*51-75*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 40100 & inctot_2019 <= 70125, cluster(msa)
*76-100*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 70125, cluster(msa)

* Baseline based on children *,
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if chborn > 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if chborn == 1, cluster(msa)

* Baseline commute based on home ownership *
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 2, cluster(msa)

* Baseline commute based on home ownership *
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 2, cluster(msa)

* Baseline with marital status as outcome * falsification
reg marst post sex inctot_2019 labforce_partic age occ racesing i.msa i.year, cluster(msa)

replace post = 1 if post > 0

* Baseline no controls *

reg commute post i.msa i.year, cluster(msa)


* Baseline with controls *

reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year, cluster(msa)

* Baseline with time specific linear time trends

reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year i.msa#c.year, cluster(msa)

* Baseline with Move as dependent and controls *

reg move post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year, cluster(msa)

* Baseline with Female Labor Force Participation as dependent and controls *

reg labforce_partic post sex inctot_2019 age occ racesing marst i.msa i.year, cluster(msa)

reg labforce_partic post inctot_2019 age occ racesing marst i.msa i.year if sex == 0, cluster(msa)

* Baseline with controls, income distribution *

*0-25th*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 <= 22000, cluster(msa)
*26-50*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 22000 & inctot_2019 <= 40100, cluster(msa)
*51-75*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 40100 & inctot_2019 <= 70125, cluster(msa)
*76-100*
reg commute post sex labforce_partic age occ racesing marst i.msa i.year if inctot_2019 > 70125, cluster(msa)

* Baseline based on children *
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if chborn > 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if chborn == 1, cluster(msa)

* Baseline commute based on home ownership *
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 2, cluster(msa)

* Baseline move based on home ownership *
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 1, cluster(msa)
reg commute post sex inctot_2019 labforce_partic age occ racesing marst i.msa i.year if ownershp == 2, cluster(msa)

* Baseline with marital status as outcome * falsification
reg marst post sex inctot_2019 labforce_partic age occ racesing i.msa i.year, cluster(msa)

* Parallel Trends *

reg commute lead3 lead2 lead1 lag1 lag2 lag3 i.msa i.year, cluster(msa)


stop

xi: reg commute ///
lead3 lead2 lead1 lead0 ///
lag1 lag2 ///
 i.msa i.year if inctot_2019 > 184000, cluster(msa)
estimates store leads_lags

coefplot leads_lags, keep( /// 
lead2 lead1 lead0 lag1 ///
lag2 ) ///
vertical title("{stSerif:{bf:Figure 1. Trends in Interstate Commuting}}", /// 
color(black) size(large)) ///
xtitle("{stSerif: Years Since Policy Came into Effect}") xscale(titlegap(2)) xline(3, lcolor(black)) ///
yline(2 ,lwidth(vvvthin) lpattern(dash) lcolor(black)) ///
note("{stSerif:{it:notes}. OLS coefficient estimate (and their 95% confidence intervals) are reported. The dependent}" ///
"{stSerif:variable is equal to the probability that indvidual {it:i} in MSA {it:a} commutes across the border}" ///
"{stSerif:year {it:t}. The controls include year fixed effects and MSA fixed effects.}", margin(small)) ///
graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) /// 
ilwidth(vvvthin)) ciopts(lwidth(*3) lcolor(black)) mcolor(black)



