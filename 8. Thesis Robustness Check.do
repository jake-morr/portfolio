capture log close
log using effect_of_policy_variable.log, replace
set linesize 255
set more off
set varabbrev off

clear all
use Effect_of_Policy_Variable.dta

keep if statefip == 27 | statefip == 55

drop commute
gen commute = 0
replace commute = 1 if minnesota_wisconsin == 1 | wisconsin_minnesota == 1

drop if year <= 2006
drop if year == 2010
drop if year > 2013

generate tax_before = 0

generate tax_after = 0

generate effect_atr = 0

replace effect_atr = (inctot * 0.0675) if statefip == 55 & year > 2010

replace effect_atr = (effect_atr / 1000)

*************
*	2010	*
*************

replace inctot = (inctot * 1.24) if year == 2007
replace inctot = (inctot * 1.95) if year == 2008
replace inctot = (inctot * 1.20) if year == 2009
replace inctot = (inctot * 1.14) if year == 2011
replace inctot = (inctot * 1.12) if year == 2012
replace inctot = (inctot * 1.11) if year == 2013

* Wisconsin tax single filer *


replace tax_before = ((inctot - 9440) * .046) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 10180 & year >= 2010

replace tax_before = ((inctot - 9440) * .0615) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 20360 & year >= 2010 & tax_before ==.

replace tax_before = ((inctot - 9440) * .0650) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 92500 & year >= 2010 & tax_before ==.

replace tax_before = (inctot * .0650) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 152740 & year >= 2010 & tax_before ==.

replace tax_before = (inctot * .0675) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 224210 & year >= 2010 & tax_before ==.

replace tax_before = (inctot  * .0775) if wisconsin_minnesota == 1 & marst >= 2 & incwage >= 224210 & year >= 2010 & tax_before ==.


* Minnesota tax single filer *

replace tax_after = ((inctot - 5450) * .0535) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 23100 & year >= 2010 & tax_after ==.

replace tax_after = ((inctot - 5450) * .0705) if wisconsin_minnesota == 1 & marst >= 2 & incwage < 75891 & year >= 2010 & tax_after ==.

replace tax_after = ((inctot - 5450) * .0785) if wisconsin_minnesota == 1 & marst >= 2 & incwage >= 75891 & year >= 2010 & tax_after ==.

* Wisconsin tax joint filer *

replace tax_before = ((inctot - 17010) * .046) if wisconsin_minnesota == 1 & marst == 1 & incwage < 13580 & year >= 2010 & tax_before ==.

replace tax_before = ((inctot - 17010) * .0615) if wisconsin_minnesota == 1 & marst == 1 & incwage < 27150 & year >= 2010 & tax_before ==.

replace tax_before = ((inctot - 17010) * .0650) if wisconsin_minnesota == 1 & marst == 1 & incwage < 105105 & year >= 2010 & tax_before ==.

replace tax_before = (inctot * .0650) if wisconsin_minnesota == 1 & marst == 1 & incwage < 203650 & year >= 2010 & tax_before ==.

replace tax_before = (inctot * .0675) if wisconsin_minnesota == 1 & marst == 1 & incwage < 298940 & year >= 2010 & tax_before ==.

replace tax_before = (inctot * .0775) if wisconsin_minnesota == 1 & marst == 1 & incwage >= 298940 & year >= 2010 & tax_before ==.


* Minnesota tax joint filer *

replace tax_after = ((inctot - 10900) * .0535) if wisconsin_minnesota == 1 & marst == 1 & incwage < 33770 & year >= 2010 & tax_after ==.

replace tax_after = ((inctot - 10900) * .0705) if wisconsin_minnesota == 1 & marst == 1 & incwage < 134170 & year >= 2010 & tax_after ==.

replace tax_after = ((inctot - 10900) * .0785) if wisconsin_minnesota == 1 & marst == 1 & incwage >= 134170 & year >= 2010 & tax_after ==.




generate effect = 0

replace effect = (tax_after - tax_before)

rename effect treatment

generate post = 0
replace post = 1 if year >= 2010

generate did = 0
replace did = (treatment * post)

*replace effect = (incwage * 
