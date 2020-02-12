# delimit; 
clear all; 
set more off; 
set maxvar 32767;
capture log close;
set seed 378297;
cd "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis";
log using "~\MCIDeM_AIM2_STUDY3_LSPQ_RTW200210.log", replace;

/* 
////////////////////////////////////////////////////////////////////////////////
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
***************************** ANALYTIC INFORMATION *****************************
MCI DeM Aim 2, Study 3: Tx preferences 
Deb Levine, MD MPH, University of Michigan
Created by Rachael Whitney, PhD: 02/06/2020
Updated by Rachael Whitney, PhD: 02/10/2020

STUDY AIM. Determine the influence of MCI on patient and study partner preferences 
for AMI and ischemic stroke treatment. STUDY HYPOTHESIS. MCI patients and study 
partners prefer less intensive treatment than patients with no MCI. 

Analyses in this syntax file employ the data from the 2020 master file freeze and 
follow the plan outlined in "MCI DeM_Study 3_Analytic Plan_RTW200102.docx". Variables
used in these analyses are detailed in the analytic plan. General note: variables 
end in suffixes that provide information about respondent type (patient or partner) 
and the person being referenced (self or dyad-mate):

	Variable contains patient information provided by the patient: _pt
	Variable contains patient information provided by the partner: _apt		
	Variable contains partner information provided by the partner: _ptr
	Variable contains dyad information provided by the partner: _dyad

---FILES IN USE---
INPUT, 2020 MASTER:	    MCIDeM_AIM2_STUDY3_MASTER_200206.dta
OUTPUT, LSPQ ANALYTIC:	MCIDeM_AIM2_STUDY3_LSPQ_200207.dta
********************************************************************************
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
*/

*************************************************************** DATA MANAGEMENT;
***** DATA IMPORT;
use "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\2020 Freeze\MCIDeM_AIM2_STUDY3_MASTER_200206.dta", clear;
*TEMPORARY FILES;
tempfile master;
tempfile consort;
save `consort';

***** EXCLUSIONS;
quietly{;
drop if cog_assessment_12mo_pt!=1;
keep if age_pt>=65 & age_pt!=.;
keep if englishspeaking_pt==1;
keep if mci_status_pt!=.;
drop if race_pt==.; 
*drop if age_ptr==.;
/* INCLUSION CRITERIA
1. Patient diagnosis of MCI or no MCI
2. Patient age >=65 years
3. Patient race White or Black
4. Patient received cog testing within 12 months of baseline
5. Patient reads and speaks English
6. Patient has a study partner age >=18 that reads and speaks English, knows the
   patient well and can answer questions about them regarding medical treatment
*/
};

***** ALTERED VARIABLES;
quietly {;
label define educ 1 "No college" 2 "Some college" 3 "4-Year degree" 4 "Graduate degree";
label define depression 0 "No indication" 1 "Some indication" 2 "Depression likely";
local define adl 0 "No difficulty" 1 "Difficulty";
local type "pt ptr";
foreach t in `type' {;
*** EDUCATION;
recode education_`t' (1 2 3 = 1) (4 5 = 2) (6 = 3) (7 = 4);
label values education_`t' educ;
*** PHQ-2;
recode phq2_`t' (1 2 = 1) (3 4 5 6 = 2);
label values phq2_`t' depression;
*** ADLS;
recode adl_`t' (1 2 3 4 5 6 = 1);
label values adl_`t' adl;
};
};

***** NEW VARIABLES;
quietly {;
*** DSRS QUARTILE;
summ dsrs_apt, detail;
gen dsrs_quartile_apt = 0 if dsrs_apt<=`r(p25)' & dsrs_apt!=.;
replace dsrs_quartile_apt = 1 if dsrs_quartile_apt==. & dsrs_apt<=`r(p50)' & dsrs_apt!=.;
replace dsrs_quartile_apt = 2 if dsrs_quartile_apt==. & dsrs_apt<=`r(p75)' & dsrs_apt!=.;
replace dsrs_quartile_apt = 3 if dsrs_quartile_apt==. & dsrs_apt!=.;
};

***** DISTRIBUTIONS;
quietly {;
*** CONTINUOUS;
local con "lspq_pt lspq_apt age_pt age_ptr relationship_yrs_dyad moca_pt dsrs_apt";
foreach var in `con'{;
swilk `var';
*qnorm `var';
};
*** BINARY;
local bin "gender_pt gender_ptr children_pt children_lives_with_pt children_30_mi_pt stroke_pt stroke_ptr heart_disease_pt heart_disease_ptr lung_disease_pt lung_disease_ptr cancer_pt cancer_ptr arthritis_pt arthritis_ptr dementia_cfamily_pt dementia_cfamily_ptr stroke_cfamily_pt stroke_cfamily_ptr heart_attack_cfamily_pt heart_attack_cfamily_ptr marital_statu_pt marital_statu_ptr";
foreach var in `bin'{;
tab `var';
};
*** CATEGORICAL;
local cat "decision_pt decision_ptr decisions_apt";
foreach var in `cat' {;
tab `var';
};
};

******************************************************* VISUAL: CONSORT DIAGRAM;
****** CONSORT DIAGRAM;
mata;
B=xl();
B.load_book("S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ");
B.delete_sheet("CONSORT Diagram");
end;

quietly{;
*** SET TEXT;
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("CONSORT Diagram") modify;
local osmall = ", box margin(small) size(vsmall) justification(left)";
local omain = ", box margin(small)";
local ohoriz = ", orientation(vertical) size(small)";
local bc = ", lwidth(medthick) lcolor(black)";
local bca = ", lwidth(medthick) lcolor(black) mlcolor(black) mlwidth(medthick) msize(medlarge)";
*DATASET BEFORE EXCLUSIONS;
save `master';
use `consort';
*TOTAL ASSESSED;
local assessed = "379";
*INELIGIBLE;
local ne = "107";
local ne_refuse = "40";
local ne_pdem = "12";
local ne_ncog = "10";
local ne_nsp = "2";
local ne_other = "43";
*ELIGIBLE;
local tot = "272";
local pt = "136";
local ptr = "136";
local nmci = "63";
local mci = "73"; 
*ATTRITION;
tab mci_status_pt race_1_pt, matcell(pt) missing;
local pt_nmci_at = pt[1,3];
local pt_mci_at = pt[2,3]+1; /* Addition to account for completely missing dyad */
local pt_at = pt[1,3]+pt[2,3]+1; 
tab mci_status_pt race_1_ptr, matcell(ptr) missing;
local ptr_nmci_at = ptr[1,3];
local ptr_mci_at = ptr[2,3]+1; /* Addition to account for completely missing dyad */
local ptr_at = ptr[1,3]+ptr[2,3]+1;
*ANALYZED;
use `master';
tab mci_status_pt, matcell(pt) missing, if race_1_pt!=.;
local pta_nmci = pt[1,1];
local pta_mci = pt[2,1];
local pta = pt[1,1]+pt[2,1]; 
tab mci_status_pt, matcell(ptr) missing, if race_1_ptr!=.;
local ptra_nmci = ptr[1,1];
local ptra_mci = ptr[2,1];
local ptra = ptr[1,1]+ptr[2,1];

*DIAGRAM;
twoway ///
   pci 5.2 0 5.2 6 `bc' || pci 5.2 6 0 6 `bc' || pci 0 6 0 0 `bc' || pci 0 0 5.2 0 `bc' ///
|| pcarrowi 4.8 3 3.5 3 `bca' ///
|| pcarrowi 4.1 3 4.1 3.35 `bca'  ///   
|| pcarrowi 3.4 3 2.9 3 `bca'  ///   
|| pci 2.86 1.7 2.86 4.3 `bc' ///
|| pcarrowi 2.86 1.71 2.6 1.71 `bca'  ///
|| pcarrowi 2.86 4.29 2.6 4.29 `bca'  ///
|| pcarrowi 2.5 1.71 1.89 1.71 `bca'  ///
|| pcarrowi 2.5 4.29 1.89 4.29 `bca'  ///
|| pcarrowi 1.8 1.71 1.12 1.71 `bca'  ///
|| pcarrowi 1.8 4.29 1.12 4.29 `bca'  ///
, ///
text(4.1 0.3 "Enrollment" `ohoriz') ///
text(2.4 0.3 "Allocation" `ohoriz') ///
text(1.6 0.3 "Follow-Up" `ohoriz') ///
text(0.7 0.3 "Analysis" `ohoriz') ///

text(4.8 3 "Assessed for eligibility (n=`assessed')" `omain') ///
text(4.1 4.4 "EXCLUDED" ///
	"•  Potential dementia (n=`ne_pdem')" ///
	"•  No study partner (n=`ne_nsp')" ///
	"•  No cognitive test (n=`ne_ncog')" ///
	"•  Refused (n=`ne_refuse')" ///		
	"•  Other (n=`ne_other')" `osmall') ///
text(3.35 3 "Participants Enrolled (n=`tot')" `omain') ///
text(2.4 1.7 "PATIENT (n=`pt')                  " ///
	"•  MCI, n=`mci'" ///
	"•  No MCI, n=`nmci'" `osmall') ///	
text(2.4 4.3 "STUDY PARTNER (n=`ptr')" ///
	"•  MCI, n=`mci'" ///
	"•  No MCI, n=`nmci'" `osmall') ///
text(1.6 1.7 "ATTRITION (n=`pt_at')" ///
	"•  Refused to participate        " ///
	"•  Too ill to complete" ///
	"•  Could not locate" ///	
	"•  Deceased" `osmall') ///
text(1.6 4.3 "ATTRITION (n=`ptr_at')" ///
	"•  Refused to participate      " ///
	"•  Too ill to complete" ///
	"•  Could not locate" ///	
	"•  Deceased" `osmall') ///
text(0.7 1.7 "ANALYZED (n=`pta')" ///
	"•  MCI, n=`pta_mci'" ///
	"•  No MCI, n=`pta_nmci'                     " ///
	" " ///
	"NOT ANALYZED (n=0)" ///
	"•  Age <65 years" ///
	"•  No cognitive test" ///
	"•  No English" `osmall') ///	
text(0.7 4.3 "ANALYZED (n=`ptra')" ///
	"•  MCI, n=`ptra_mci'" ///
	"•  No MCI, n=`ptra_nmci'                   " ///
	" " ///
	"NOT ANALYZED (n=0)" ///
	"•  Age <65 years" ///
	"•  No cognitive test" ///
	"•  No English" `osmall') ///	
legend(off) ///
xlabel("") ylabel("") xtitle("") ytitle("") ///
plotregion(lcolor(black)) ///
graphregion(lcolor(black)) xscale(range(0 6)) ///
xsize(2) ysize(3) ///
title("CONSORT Diagram");
graph export consort.png, replace;
putexcel A1 = picture(consort.png);
};

***************************************** ANALYSIS: PARTICIPANT CHARACTERISTICS;
***** TABLE 1: _PT;
quietly {;
*** SET TEXT;
tab mci_status_pt, matcell(dyad), if race_1_pt!=.;
local ntot = dyad[1,1]+dyad[2,1];
local nnmci = dyad[1,1];
local nmci = dyad[2,1];
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("Table 1") modify; 
putexcel A1 = "Table 1. Patient characteristics by MCI status (n=`ntot').", top left underline;
putexcel A3:A4 = "Variable", merge bold top left; 
putexcel B3:C3 = "Patient MCI Status", merge bold top left; 
putexcel D3:D4 = "p-value", merge bold top left; 
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5 = "Age, years";
putexcel A6 = "MoCA, points";
putexcel A7 = "LSPQ, points"; 
putexcel A8 = "Site, % UM";
putexcel A9 = "Race, % Black";
putexcel A10 = "Gender, % female";
putexcel A11 = "Education, %";
putexcel A12 = "    No college"; 
putexcel A13 = "    Some college"; 
putexcel A14 = "    4-Year degree"; 
putexcel A15 = "    Graduate degree"; 
putexcel A16 = "Marital status, %";
putexcel A17 = "    Married"; 
putexcel A18 = "    Live-in partner"; 
putexcel A19 = "    Divorced or separated"; 
putexcel A20 = "    Widowed"; 
putexcel A21 = "    Never married"; 
putexcel A22 = "Has children, %";
putexcel A23 = "Lives with child, %";
putexcel A24 = "Child within 30 miles, %";
putexcel A25 = "Self-rated health, %";
putexcel A26 = "    Excellent"; 
putexcel A27 = "    Very good"; 
putexcel A28 = "    Good"; 
putexcel A29 = "    Fair"; 
putexcel A30 = "Depression, %";
putexcel A31 = "    No indication"; 
putexcel A32 = "    Some indication"; 
putexcel A33 = "    Depression likely"; 
putexcel A34 = "Difficulty with ADLs, %";
putexcel A35 = "Disease history, %";
putexcel A36 = "    Stroke";
putexcel A37 = "    Heart disease";
putexcel A38 = "    Lung disease";
putexcel A39 = "    Cancer";
putexcel A40 = "    Arthritis";
putexcel A41 = "Contact history, %";
putexcel A42 = "    Dementia";
putexcel A43 = "    Stroke";
putexcel A44 = "    Heart attack";
*** Cell data;
*AGE;
ttest age_pt, by(mci_status_pt), if race_1_pt!=.;
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B5 = "`msry1'";
putexcel C5 = "`msry2'"; 
putexcel D5 = (r(p)), nformat(0.000) left;
*MoCA;
ttest moca_pt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B6 = "`msry1'";
putexcel C6 = "`msry2'"; 
putexcel D6 = (r(p)), nformat(0.000) left;
*LSPQ;
ttest lspq_pt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B7 = "`msry1'";
putexcel C7 = "`msry2'"; 
putexcel D7 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if race_1_pt!=.;
putexcel D8 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local x`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'8 = "`x`i''";
};
*RACE;
tab race_pt mci_status_pt, matcell(race) chi2, if race_1_pt!=.;
putexcel D9 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = race[1,`i']+race[2,`i'];
local x`i' = string((race[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'9 = "`x`i''";
};
*GENDER;
tab gender_pt mci_status_pt, matcell(fm) chi2, if race_1_pt!=.;
putexcel D10 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = fm[1,`i']+fm[2,`i'];
local x`i' = string((fm[1,`i']/`M`i'')*100, "%9.1f");
putexcel `var'10 = "`x`i''";
};
*EDUCATION;
tab education_pt mci_status_pt, matcell(edu) chi2;
putexcel D11 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(11+`j');
local M`i' = edu[1,`i']+edu[2,`i']+edu[3,`i']+edu[4,`i'];
local x`j' = string((edu[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*MARITAL STATUS;
tab marital_statu_pt mci_status_pt, matcell(mar) chi2;
putexcel D16 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(16+`j');
local M`i' = mar[1,`i']+mar[2,`i']+mar[3,`i']+mar[4,`i']+mar[5,`i'];
local x`j' = string((mar[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*CHILDREN;
local child "children_pt children_lives_with_pt children_30_mi_pt";
local numcell : word count `child';
forvalues i=1/`numcell' {;
local var : word `i' of `child';
tab `var' mci_status_pt, matcell(child) chi2;
local num = string(21+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i' = child[1,`i']+child[2,`i'];
local x`i2' = string((child[2,`i2']/`M`i2'')*100, "%9.1f");
putexcel `var2'`num' = "`x`i2''";
};
};
*HEALTH;
tab health_pt mci_status_pt, matcell(heal) chi2;
putexcel D25 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(25+`j');
local M`i' = heal[1,`i']+heal[2,`i']+heal[3,`i']+heal[4,`i'];
local x`j' = string((heal[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*PHQ2;
tab phq2_pt mci_status_pt, matcell(dep) chi2;
putexcel D30 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(30+`j');
local M`i' = dep[1,`i']+dep[2,`i']+dep[3,`i'];
local x`j' = string((dep[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*ADL DIFFICULTY;
tab adl_pt mci_status_pt, matcell(adl) chi2, if race_1_pt!=.;
putexcel D34 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = adl[1,`i']+adl[2,`i'];
local x`i' = string((adl[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'34 = "`x`i''";
};
*DISEASE HISTORY;
local history "stroke_pt heart_disease_pt lung_disease_pt cancer_pt arthritis_pt";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(35+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i' = history[1,`i']+history[2,`i'];
local x`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
putexcel `var2'`num' = "`x`i2''";
};
};
*CONTACT HISTORY;
local history "dementia_cfamily_pt stroke_cfamily_pt heart_attack_cfamily_pt";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(41+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i' = history[1,`i']+history[2,`i'];
local x`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
putexcel `var2'`num' = "`x`i2''";
};
};
};

***** TABLE 2: _PTR;
quietly {;
*** SET TEXT;
tab mci_status_pt, matcell(dyad), if race_1_ptr!=.;
local ntot = dyad[1,1]+dyad[2,1];
local nnmci = dyad[1,1];
local nmci = dyad[2,1];
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("Table 2") modify; 
putexcel A1 = "Table 2. Study partner characteristics by patient MCI status (n=`ntot').", top left underline;
putexcel A3:A4 = "Variable", merge bold top left; 
putexcel B3:C3 = "Patient MCI Status", merge bold top left; 
putexcel D3:D4 = "p-value", merge bold top left; 
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5 = "Age, years"; 
putexcel A6 = "Site, % UM";
putexcel A7 = "Race, % Black";
putexcel A8 = "Gender, % female";
putexcel A9 = "Education, %";
putexcel A10 = "    No college"; 
putexcel A11 = "    Some college"; 
putexcel A12 = "    4-Year degree"; 
putexcel A13 = "    Graduate degree";
putexcel A14 = "Marital status, %";
putexcel A15 = "    Married"; 
putexcel A16 = "    Live-in partner"; 
putexcel A17 = "    Divorced or separated"; 
putexcel A18 = "    Widowed"; 
putexcel A19 = "    Never married";
putexcel A20 = "Self-rated health, %";
putexcel A21 = "    Excellent"; 
putexcel A22 = "    Very good"; 
putexcel A23 = "    Good"; 
putexcel A24 = "    Fair"; 
putexcel A25 = "Depression, %";
putexcel A26 = "    No indication"; 
putexcel A27 = "    Some indication"; 
putexcel A28 = "    Depression likely"; 
putexcel A29 = "Difficulty with ADLs, %";
putexcel A30 = "Disease history, %";
putexcel A31 = "    Stroke";
putexcel A32 = "    Heart disease";
putexcel A33 = "    Lung disease";
putexcel A34 = "    Cancer";
putexcel A35 = "    Arthritis";
putexcel A36 = "Contact history, %";
putexcel A37 = "    Dementia";
putexcel A38 = "    Stroke";
putexcel A39 = "    Heart attack";
*** Cell data;
*AGE;
ttest age_ptr, by(mci_status_pt), if race_1_ptr!=.;
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B5 = "`msry1'";
putexcel C5 = "`msry2'"; 
putexcel D5 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if race_1_ptr!=.;
putexcel D6 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local x`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'6 = "`x`i''";
};
*RACE;
tab race_ptr mci_status_pt, matcell(race) chi2, if race_1_ptr!=.;
putexcel D7 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = race[1,`i']+race[2,`i']+race[3,`i'];
local x`i' = string((race[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'7 = "`x`i''";
};
*GENDER;
tab gender_ptr mci_status_pt, matcell(fm) chi2, if race_1_ptr!=.;
putexcel D8 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = fm[1,`i']+fm[2,`i'];
local x`i' = string((fm[1,`i']/`M`i'')*100, "%9.1f");
putexcel `var'8 = "`x`i''";
};
*EDUCATION;
tab education_ptr mci_status_pt, matcell(edu) chi2;
putexcel D9 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(9+`j');
local M`i' = edu[1,`i']+edu[2,`i']+edu[3,`i']+edu[4,`i'];
local x`j' = string((edu[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*MARITAL STATUS;
tab marital_statu_ptr mci_status_pt, matcell(mar) chi2;
putexcel D14 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(14+`j');
local M`i' = mar[1,`i']+mar[2,`i']+mar[3,`i']+mar[4,`i']+mar[5,`i'];
local x`j' = string((mar[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*HEALTH;
tab health_ptr mci_status_pt, matcell(heal) chi2;
putexcel D20 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(20+`j');
local M`i' = heal[1,`i']+heal[2,`i']+heal[3,`i']+heal[4,`i'];
local x`j' = string((heal[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*PHQ2;
tab phq2_ptr mci_status_pt, matcell(dep) chi2;
putexcel D25 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(25+`j');
local M`i' = dep[1,`i']+dep[2,`i']+dep[3,`i'];
local x`j' = string((dep[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*ADL DIFFICULTY;
tab adl_ptr mci_status_pt, matcell(adl) chi2, if race_1_ptr!=.;
putexcel D29 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = adl[1,`i']+adl[2,`i'];
local x`i' = string((adl[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'29 = "`x`i''";
};
*DISEASE HISTORY;
local history "stroke_ptr heart_disease_ptr lung_disease_ptr cancer_ptr arthritis_ptr";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(30+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i' = history[1,`i']+history[2,`i'];
local x`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
putexcel `var2'`num' = "`x`i2''";
};
};
*CONTACT HISTORY;
local history "dementia_cfamily_ptr stroke_cfamily_ptr heart_attack_cfamily_ptr";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(36+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i' = history[1,`i']+history[2,`i'];
local x`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
putexcel `var2'`num' = "`x`i2''";
};
};
};

***** TABLE 3: _APT;
quietly{;
*** SET TEXT;
tab mci_status_pt, matcell(dyad), if race_1_ptr!=.;
local ntot = dyad[1,1]+dyad[2,1];
local nnmci = dyad[1,1];
local nmci = dyad[2,1];
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("Table 3") modify; 
putexcel A1 = "Table 3. Indices of patient function by MCI status, as reported by study partners (n=`ntot').", top left underline;
putexcel A3:A4 = "Variable", merge bold top left; 
putexcel B3:C3 = "Patient MCI Status", merge bold top left; 
putexcel D3:D4 = "p-value", merge bold top left; 
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5 = "LSPQ, points"; 
putexcel A6 = "DSRS, points"; 
putexcel A7 = "Site, % UM";
putexcel A8 = "Memory, %";
putexcel A9 = "    Normal memory"; 
putexcel A10 = "    Occasionally forgetful"; 
putexcel A11 = "    Consistently forgetful"; 
putexcel A12 = "    Moderate memory loss"; 
putexcel A13 = "    Substantial memory loss";
putexcel A14 = "Decision making, %";
putexcel A15 = "    Normal ability"; 
putexcel A16 = "    Some difficulty"; 
putexcel A17 = "    Moderate difficulty"; 
putexcel A18 = "    Rarely makes decisions"; 
putexcel A19 = "Orientation to time, %";
putexcel A20 = "    Normal orientation"; 
putexcel A21 = "    Some disorientation"; 
putexcel A22 = "    Frequent disorientation"; 
putexcel A23 = "Orientation to place, %";
putexcel A24 = "    Normal orientation"; 
putexcel A25 = "    Some disorientation"; 
putexcel A26 = "    Frequent disorientation"; 
putexcel A27 = "Language ability, %";
putexcel A28 = "    Normal language"; 
putexcel A29 = "    Some difficulty"; 
putexcel A30 = "    Frequent difficulty"; 
putexcel A31 = "    Rarely converses"; 
putexcel A32 = "    Hard to understand"; 
putexcel A33 = "Social interaction, %";
putexcel A34 = "    Normal interaction"; 
putexcel A35 = "    Some difficulty"; 
putexcel A36 = "    Frequent difficulty"; 
putexcel A37 = "    Needs help to interact"; 
putexcel A38 = "Task completion, %";
putexcel A39 = "    Normal ability"; 
putexcel A40 = "    Trouble with difficult task"; 
putexcel A41 = "    Trouble with easy task";
putexcel A42 = "Personal care, %";
putexcel A43 = "    Normal ability"; 
putexcel A44 = "    Sometimes forgets"; 
putexcel A45 = "Bladder and bowel control, %";
putexcel A46 = "    Normal control"; 
putexcel A47 = "    Rarely fails to control"; 
putexcel A48 = "    Occasional fails to control"; 
putexcel A49 = "    Frequently fails to control";
putexcel A50 = "Navigation, %";
putexcel A51 = "    Normal ability"; 
putexcel A52 = "    Can walk alone outside";
putexcel A53 = "    Can walk short distances alone"; 
*** Cell data;
*LSPQ;
ttest lspq_apt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B5 = "`msry1'";
putexcel C5 = "`msry2'"; 
putexcel D5 = (r(p)), nformat(0.000) left;
*DSRS;
ttest dsrs_apt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B6 = "`msry1'";
putexcel C6 = "`msry2'"; 
putexcel D6 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if race_1_ptr!=.;
putexcel D7 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local x`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'7 = "`x`i''";
};
*MEMORY;
tab memory_apt mci_status_pt, matcell(mem) chi2;
putexcel D8 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(8+`j');
local M`i' = mem[1,`i']+mem[2,`i']+mem[3,`i']+mem[4,`i']+mem[5,`i'];
local x`j' = string((mem[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*DECISIONS;
tab decisions_apt mci_status_pt, matcell(dec) chi2;
putexcel D14 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(14+`j');
local M`i' = dec[1,`i']+dec[2,`i']+dec[3,`i']+dec[4,`i'];
local x`j' = string((dec[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*ORIENTATION TO TIME;
tab orientation_to_time_apt mci_status_pt, matcell(ort) chi2;
putexcel D19 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(19+`j');
local M`i' = ort[1,`i']+ort[2,`i']+ort[3,`i'];
local x`j' = string((ort[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*ORIENTATION TO PLACE;
tab orientation_to_place_apt mci_status_pt, matcell(orp) chi2;
putexcel D23 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(23+`j');
local M`i' = orp[1,`i']+orp[2,`i']+orp[3,`i'];
local x`j' = string((orp[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*SPEECH AND LANGUAGE;
tab speech_and_language_apt mci_status_pt, matcell(spl) chi2;
putexcel D27 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(27+`j');
local M`i' = spl[1,`i']+spl[2,`i']+spl[3,`i']+spl[4,`i']+spl[5,`i'];
local x`j' = string((spl[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*SOCIAL AND COMMUNITY;
tab social_and_community_apt mci_status_pt, matcell(soc) chi2;
putexcel D33 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(33+`j');
local M`i' = soc[1,`i']+soc[2,`i']+soc[3,`i']+soc[4,`i'];
local x`j' = string((soc[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*ACTIVITIES; 
tab activities_and_respons_apt mci_status_pt, matcell(act) chi2;
putexcel D38 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(38+`j');
local M`i' = act[1,`i']+act[2,`i']+act[3,`i'];
local x`j' = string((act[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*PERSONAL CARE;
tab personal_care_apt mci_status_pt, matcell(pc) chi2;
putexcel D42 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/2{;
local num = string(42+`j');
local M`i' = pc[1,`i']+pc[2,`i'];
local x`j' = string((pc[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*TOILETING;
tab urination_and_bowels_apt mci_status_pt, matcell(toi) chi2;
putexcel D45 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(45+`j');
local M`i' = toi[1,`i']+toi[2,`i']+toi[3,`i']+toi[4,`i'];
local x`j' = string((toi[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*NAVIGATING;
tab place_to_place_apt mci_status_pt, matcell(nav) chi2;
putexcel D50 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(50+`j');
local M`i' = nav[1,`i']+nav[2,`i']+nav[3,`i'];
local x`j' = string((nav[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
/* NOTE
Study partner's were also asked about their patient's eating level. The eating
level variable contained no variation, with all partner's answering "normal".
The eating level variable is omitted from this table and statistical analysis.
*/
};

***** TABLE 4: _DYAD;
quietly {;
*** SET TEXT;
tab mci_status_pt, matcell(dyad), if complete_dyad==1;
local ntot = dyad[1,1]+dyad[2,1];
local nnmci = dyad[1,1];
local nmci = dyad[2,1];
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("Table 4") modify; 
putexcel A1 = "Table 4. Dyad characteristics by patient MCI status (n=`ntot' dyads).", top left underline;
putexcel A3:A4 = "Variable", merge bold top left; 
putexcel B3:C3 = "Patient MCI Status", merge bold top left; 
putexcel D3:D4 = "p-value", merge bold top left; 
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5 = "Relationship length, years"; 
putexcel A6 = "Site, % UM";
putexcel A7 = "Relationship type, %";
putexcel A8 = "    Child"; 
putexcel A9 = "    Sibling"; 
putexcel A10 = "    Spouse"; 
putexcel A11 = "    Companion"; 
putexcel A12 = "    Friend"; 
putexcel A13 = "    Parent";
putexcel A14 = "    Other";
putexcel A15 = "Physical interaction, %";
putexcel A16 = "     Daily, live together";
putexcel A17 = "     Daily, live apart";
putexcel A18 = "     Several times per week";
putexcel A19 = "     Once per week";
putexcel A20 = "     1-3 Times per month";
putexcel A21 = "     <1 Time per month";
putexcel A22 = "Verbal interaction, %";
putexcel A23 = "     Daily";
putexcel A24 = "     Several times per week";
putexcel A25 = "     Once per week";
putexcel A26 = "     1-3 Times per month";
putexcel A27 = "     <1 Time per month";
*** Cell data;
*RELATIONSHIP LENGTH;
ttest relationship_yrs_dyad, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B5 = "`msry1'";
putexcel C5 = "`msry2'"; 
putexcel D5 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if complete_dyad==1;
putexcel D6 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local x`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
putexcel `var'6 = "`x`i''";
};
*RELATIONSHIP TYPE;
tab relationship_dyad mci_status_pt, matcell(rt) chi2;
putexcel D7 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/7{;
local num = string(7+`j');
local M`i' = rt[1,`i']+rt[2,`i']+rt[3,`i']+rt[4,`i']+rt[5,`i']+rt[6,`i']+rt[7,`i'];
local x`j' = string((rt[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*PHYSICAL INTERACTION;
tab freq_see_dyad mci_status_pt, matcell(fse) chi2;
putexcel D15 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/6{;
local num = string(15+`j');
local M`i' = fse[1,`i']+fse[2,`i']+fse[3,`i']+fse[4,`i']+fse[5,`i']+fse[6,`i'];
local x`j' = string((fse[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
*VERBAL INTERACTION; 
tab freq_speak_dyad mci_status_pt, matcell(fsp) chi2;
putexcel D22 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(22+`j');
local M`i' = fsp[1,`i']+fsp[2,`i']+fsp[3,`i']+fsp[4,`i']+fsp[5,`i'];
local x`j' = string((fsp[`j',`i']/`M`i'')*100, "%9.1f");
putexcel `var'`num' = "`x`j''";
};
};
};

*********************************************** ANALYSIS: TREATMENT PREFERENCES;
***** PRIMARY 1;
***** SECONDARY 1;
***** SECONDARY 2;
***** SENSITIVITY;

************************************************* ANALYSIS: PREFERENCES FOR SDM;
***** SECONDARY 1;
***** SECONDARY 2;
***** SENSITIVITY;

**************** ANALYSIS: PREFERENCES FOR SDM IN AMI AND ACUTE ISCHEMIC STROKE;
***** SECONDARY 1;
***** SECONDARY 2;
***** SENSITIVITY;

****************************************************** ANALYSIS: RISK PERCEPTION;
***** SECONDARY 1;
***** SECONDARY 2;
***** SENSITIVITY;

/*******************************************************************************
---------------------------------- QUESTIONS -----------------------------------

							\\\ DATA MANAGEMENT ///

1. We specify in analytic plan that having a study parter is an inclusion criterion. 
Should we remove the 5 partners that didn't return a survey? If we keep them, should
we impute some of their personal characteristics (e.g., age, sex, race)?
---
2. Do we want to use DSRS continuously (skewed) or recode into a categorical 
variable (quartiles)? Continuous is very positively skewed.
---
3. Age somewhat skewed. For patients, fewer people at higher ages beginning around 
82. For partners, fewer people at younger ages beginning around 60 and higher ages
beginning around 84. Could winsorize.
---
4. Length of patient-partner relationship somewhat skewed, with 18 people out of 111
having less than a 30 year relationship (range 3 to 75 years). Thoughts? 
---
5. MOCA somewhat skewed, with fewer people having very low scores and a smaller
number maxing out. Could winsorize.   
---
6. Binary variables with small cell sizes (<10): stroke_pt stroke_ptr lung_disease_ptr
---
7. FOR TWO DYADS, neither patient nor partner returned the survey. These are not
included. Do we want to include them? We could get patient information from the 
tracker and impute some of the partner characteristics. 
---
NOTE: People typically filled out the entire survey. Few missing values within 
observed participants. Missingness comes from attrition.
--------------------------------------------------------------------------------
*******************************************************************************/

************************************************************** ANALYTIC DATASET;
save "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ_RTW200210.dta", replace;
***** LOG;
capture log close; 
translate "~\MCIDeM_AIM2_STUDY3_LSPQ_RTW200210.log"
"~\MCIDeM_AIM2_STUDY3_LSPQ_RTW200210.pdf";
