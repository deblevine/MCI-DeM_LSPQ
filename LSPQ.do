# delimit; 
clear all; 
set more off; 
set maxvar 32767;
capture log close;
set seed 378297;

/* 
////////////////////////////////////////////////////////////////////////////////
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
***************************** ANALYTIC INFORMATION *****************************
MCI DeM Aim 2, Study 3: Tx preferences 
Deb Levine, MD MPH, University of Michigan
Created by Rachael Whitney, PhD: 02/06/2020
Updated by Rachael Whitney, PhD: 03/30/2020

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
OUTPUT, LSPQ ANALYTIC:	MCIDeM_AIM2_STUDY3_LSPQ_`date'.dta
********************************************************************************
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
*/

**************************************************************** PROGRAM MACROS;
*** DIRECTORY;
cd "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis";
*** DATE;
local date "200403";
*** LOG;
local log "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ_RTW`date'.log";
*** IN PATH;
local inpath = "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\2020 Freeze\MCIDeM_AIM2_STUDY3_MASTER_200206.dta";
*** OUT PATH;
local outpath = "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ_RTW`date'.dta";
*** OTHER;
local letter "A B C D";

*************************************************************** DATA MANAGEMENT;
***** DATA FILES;
*MASTER;
log using "`log'", replace;
use "`inpath'", clear;
*TEMP;
tempfile master;
tempfile strobe;
save `strobe';

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
*** SITE;
gen x = site=="UMDL";
drop site;
rename x site;
label define site 0 "DUDL" 1 "UMDL";
label values site site;
*** LSPQ REVERSE CODING;
gen lspq_reverse_pt = 24-lspq_pt;
gen lspq_reverse_apt = 24-lspq_apt;
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
putexcel A3:A4 = "Variable", merge bold top left border(top, thin, black); 
putexcel B3:C3 = "Patient MCI Status", merge bold top left border(top, thin, black); 
putexcel D3:D4 = "p-value", merge bold top left border(top, thin, black);  
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5:D5 = "Mean (SD)", merge italic left border(top, thin, black); ;
putexcel A6 = "Age, years";
putexcel A7 = "MoCA, points";
putexcel A8 = "LSPQ, points"; 
putexcel A9:D9 = "Count (%)", merge italic left;
putexcel A10 = "Site, UM";
putexcel A11 = "Race, Black";
putexcel A12 = "Gender, female";
putexcel A13 = "Education";
putexcel A14 = "    No college"; 
putexcel A15 = "    Some college"; 
putexcel A16 = "    4-Year degree"; 
putexcel A17 = "    Graduate degree"; 
putexcel A18 = "Marital status";
putexcel A19 = "    Married"; 
putexcel A20 = "    Live-in partner"; 
putexcel A21 = "    Divorced or separated"; 
putexcel A22 = "    Widowed"; 
putexcel A23 = "    Never married"; 
putexcel A24 = "Has children";
putexcel A25 = "Lives with child";
putexcel A26 = "Child within 30 miles";
putexcel A27 = "Self-rated health";
putexcel A28 = "    Excellent"; 
putexcel A29 = "    Very good"; 
putexcel A30 = "    Good"; 
putexcel A31 = "    Fair"; 
putexcel A32 = "Depression";
putexcel A33 = "    No indication"; 
putexcel A34 = "    Some indication"; 
putexcel A35 = "    Depression likely"; 
putexcel A36 = "Difficulty with ADLs";
putexcel A37 = "Disease history";
putexcel A38 = "    Stroke";
putexcel A39 = "    Heart disease";
putexcel A40 = "    Lung disease";
putexcel A41 = "    Cancer";
putexcel A42 = "    Arthritis";
putexcel A43 = "Contact history";
putexcel A44 = "    Dementia";
putexcel A45 = "    Stroke";
foreach l in `letter' {;
putexcel `l'46 = " ",  border(bottom, thin, black);
};
putexcel A46 = "    Heart attack";
*** Cell data;
*AGE;
ttest age_pt, by(mci_status_pt), if race_1_pt!=.;
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B6 = "`msry1'";
putexcel C6 = "`msry2'"; 
putexcel D6 = (r(p)), nformat(0.000) left;
*MoCA;
ttest moca_pt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B7 = "`msry1'";
putexcel C7 = "`msry2'"; 
putexcel D7 = (r(p)), nformat(0.000) left;
*LSPQ;
ttest lspq_reverse_pt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B8 = "`msry1'";
putexcel C8 = "`msry2'"; 
putexcel D8 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if race_1_pt!=.;
putexcel D10 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local P`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = ss[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'10 = "`x`i''";
};
*RACE;
tab race_pt mci_status_pt, matcell(race) chi2, if race_1_pt!=.;
putexcel D11 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = race[1,`i']+race[2,`i'];
local P`i' = string((race[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = race[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'11 = "`x`i''";
};
*GENDER;
tab gender_pt mci_status_pt, matcell(fm) chi2, if race_1_pt!=.;
putexcel D12 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = fm[1,`i']+fm[2,`i'];
local P`i' = string((fm[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = fm[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'12 = "`x`i''";
};
*EDUCATION;
tab education_pt mci_status_pt, matcell(edu) chi2;
putexcel D13 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(13+`j');
local M`i' = edu[1,`i']+edu[2,`i']+edu[3,`i']+edu[4,`i'];
local P`j' = string((edu[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = edu[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*MARITAL STATUS;
tab marital_statu_pt mci_status_pt, matcell(mar) chi2;
putexcel D18 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(18+`j');
local M`i' = mar[1,`i']+mar[2,`i']+mar[3,`i']+mar[4,`i']+mar[5,`i'];
local P`j' = string((mar[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = mar[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*CHILDREN;
local child "children_pt children_lives_with_pt children_30_mi_pt";
local numcell : word count `child';
forvalues i=1/`numcell' {;
local var : word `i' of `child';
tab `var' mci_status_pt, matcell(child) chi2;
local num = string(23+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i2' = child[1,`i2']+child[2,`i2'];
local P`i2' = string((child[2,`i2']/`M`i2'')*100, "%9.1f");
local C`i2' = child[2,`i2'];
local x`i2' = "`C`i2'' (`P`i2'')";
putexcel `var2'`num' = "`x`i2''";
};
};
*HEALTH;
tab health_pt mci_status_pt, matcell(heal) chi2;
putexcel D27 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(27+`j');
local M`i' = heal[1,`i']+heal[2,`i']+heal[3,`i']+heal[4,`i'];
local P`j' = string((heal[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = heal[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*PHQ2;
tab phq2_pt mci_status_pt, matcell(dep) chi2;
putexcel D32 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(32+`j');
local M`i' = dep[1,`i']+dep[2,`i']+dep[3,`i'];
local P`j' = string((dep[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = dep[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*ADL DIFFICULTY;
tab adl_pt mci_status_pt, matcell(adl) chi2, if race_1_pt!=.;
putexcel D36 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = adl[1,`i']+adl[2,`i'];
local P`i' = string((adl[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = adl[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'36 = "`x`i''";
};
*DISEASE HISTORY;
local history "stroke_pt heart_disease_pt lung_disease_pt cancer_pt arthritis_pt";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(37+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i2' = history[1,`i2']+history[2,`i2'];
local P`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
local C`i2' = history[2,`i2'];
local x`i2' = "`C`i2'' (`P`i2'')";
putexcel `var2'`num' = "`x`i2''";
};
};
*CONTACT HISTORY;
local history "dementia_cfamily_pt stroke_cfamily_pt heart_attack_cfamily_pt";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(43+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i2' = history[1,`i2']+history[2,`i2'];
local P`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
local C`i2' = history[2,`i2'];
local x`i2' = "`C`i2'' (`P`i2'')";
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
putexcel A3:A4 = "Variable", merge bold top left border(top, thin, black); 
putexcel B3:C3 = "Patient MCI Status", merge bold top left border(top, thin, black); 
putexcel D3:D4 = "p-value", merge bold top left border(top, thin, black);  
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5:D5 = "Mean (SD)", merge italic left border(top, thin, black); ;
putexcel A6 = "Age, years";
putexcel A7:D7 = "Count (%)", merge italic left;
putexcel A8 = "Site, UM";
putexcel A9 = "Race, Black";
putexcel A10 = "Gender, female";
putexcel A11 = "Education";
putexcel A12 = "    No college"; 
putexcel A13 = "    Some college"; 
putexcel A14 = "    4-Year degree"; 
putexcel A15 = "    Graduate degree";
putexcel A16 = "Marital status";
putexcel A17 = "    Married"; 
putexcel A18 = "    Live-in partner"; 
putexcel A19 = "    Divorced or separated"; 
putexcel A20 = "    Widowed"; 
putexcel A21 = "    Never married";
putexcel A22 = "Self-rated health";
putexcel A23 = "    Excellent"; 
putexcel A24 = "    Very good"; 
putexcel A25 = "    Good"; 
putexcel A26 = "    Fair"; 
putexcel A27 = "Depression";
putexcel A28 = "    No indication"; 
putexcel A29 = "    Some indication"; 
putexcel A30 = "    Depression likely"; 
putexcel A31 = "Difficulty with ADLs";
putexcel A32 = "Disease history";
putexcel A33 = "    Stroke";
putexcel A34 = "    Heart disease";
putexcel A35 = "    Lung disease";
putexcel A36 = "    Cancer";
putexcel A37 = "    Arthritis";
putexcel A38 = "Contact history";
putexcel A39 = "    Dementia";
putexcel A40 = "    Stroke";
foreach l in `letter' {;
putexcel `l'41 = " ",  border(bottom, thin, black);
};
putexcel A41 = "    Heart attack";

*** Cell data;
*AGE;
ttest age_ptr, by(mci_status_pt), if race_1_ptr!=.;
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
putexcel D8 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local P`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = ss[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'8 = "`x`i''";
};
*RACE;
tab race_ptr mci_status_pt, matcell(race) chi2, if race_1_ptr!=.;
putexcel D9 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = race[1,`i']+race[2,`i']+race[3,`i'];
local P`i' = string((race[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = race[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'9 = "`x`i''";
};
*GENDER;
tab gender_ptr mci_status_pt, matcell(fm) chi2, if race_1_ptr!=.;
putexcel D10 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = fm[1,`i']+fm[2,`i'];
local P`i' = string((fm[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = fm[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'10 = "`x`i''";
};
*EDUCATION;
tab education_ptr mci_status_pt, matcell(edu) chi2;
putexcel D11 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(11+`j');
local M`i' = edu[1,`i']+edu[2,`i']+edu[3,`i']+edu[4,`i'];
local P`j' = string((edu[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = edu[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*MARITAL STATUS;
tab marital_statu_ptr mci_status_pt, matcell(mar) chi2;
putexcel D16 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(16+`j');
local M`i' = mar[1,`i']+mar[2,`i']+mar[3,`i']+mar[4,`i']+mar[5,`i'];
local P`j' = string((mar[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = mar[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*HEALTH;
tab health_ptr mci_status_pt, matcell(heal) chi2;
putexcel D22 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(22+`j');
local M`i' = heal[1,`i']+heal[2,`i']+heal[3,`i']+heal[4,`i'];
local P`j' = string((heal[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = heal[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*PHQ2;
tab phq2_ptr mci_status_pt, matcell(dep) chi2;
putexcel D27 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(27+`j');
local M`i' = dep[1,`i']+dep[2,`i']+dep[3,`i'];
local P`j' = string((dep[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = dep[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*ADL DIFFICULTY;
tab adl_ptr mci_status_pt, matcell(adl) chi2, if race_1_ptr!=.;
putexcel D31 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = adl[1,`i']+adl[2,`i'];
local P`i' = string((adl[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = adl[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'31 = "`x`i''";
};
*DISEASE HISTORY;
local history "stroke_ptr heart_disease_ptr lung_disease_ptr cancer_ptr arthritis_ptr";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(32+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i2' = history[1,`i2']+history[2,`i2'];
local P`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
local C`i2' = history[2,`i2'];
local x`i2' = "`C`i2'' (`P`i2'')";
putexcel `var2'`num' = "`x`i2''";
};
};
*CONTACT HISTORY;
local history "dementia_cfamily_ptr stroke_cfamily_ptr heart_attack_cfamily_ptr";
local numcell : word count `history';
forvalues i=1/`numcell' {;
local var : word `i' of `history';
tab `var' mci_status_pt, matcell(history) chi2;
local num = string(38+`i');
putexcel D`num' = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell2 : word count `letter';
forvalues i2=1/`numcell2' {;
local var2 : word `i2' of `letter';
local M`i2' = history[1,`i2']+history[2,`i2'];
local P`i2' = string((history[2,`i2']/`M`i2'')*100, "%9.1f");
local C`i2' = history[2,`i2'];
local x`i2' = "`C`i2'' (`P`i2'')";
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
putexcel A3:A4 = "Variable", merge bold top left border(top, thin, black); 
putexcel B3:C3 = "Patient MCI Status", merge bold top left border(top, thin, black); 
putexcel D3:D4 = "p-value", merge bold top left border(top, thin, black);  
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5:D5 = "Mean (SD)", merge italic left border(top, thin, black); 
putexcel A6 = "LSPQ, points"; 
putexcel A7 = "DSRS, points"; 
putexcel A8:D8 = "Count (%)", merge italic left;
putexcel A9 = "Site, UM";
putexcel A10 = "Memory";
putexcel A11 = "    Normal memory"; 
putexcel A12 = "    Occasionally forgetful"; 
putexcel A13 = "    Consistently forgetful"; 
putexcel A14 = "    Moderate memory loss"; 
putexcel A15 = "    Substantial memory loss";
putexcel A16 = "Decision making";
putexcel A17 = "    Normal ability"; 
putexcel A18 = "    Some difficulty"; 
putexcel A19 = "    Moderate difficulty"; 
putexcel A20 = "    Rarely makes decisions"; 
putexcel A21 = "Orientation to time";
putexcel A22 = "    Normal orientation"; 
putexcel A23 = "    Some disorientation"; 
putexcel A24 = "    Frequent disorientation"; 
putexcel A25 = "Orientation to place";
putexcel A26 = "    Normal orientation"; 
putexcel A27 = "    Some disorientation"; 
putexcel A28 = "    Frequent disorientation"; 
putexcel A29 = "Language ability";
putexcel A30 = "    Normal language"; 
putexcel A31 = "    Some difficulty"; 
putexcel A32 = "    Frequent difficulty"; 
putexcel A33 = "    Rarely converses"; 
putexcel A34 = "    Hard to understand"; 
putexcel A35 = "Social interaction";
putexcel A36 = "    Normal interaction"; 
putexcel A37 = "    Some difficulty"; 
putexcel A38 = "    Frequent difficulty"; 
putexcel A39 = "    Needs help to interact"; 
putexcel A40 = "Task completion";
putexcel A41 = "    Normal ability"; 
putexcel A42 = "    Trouble with difficult task"; 
putexcel A43 = "    Trouble with easy task";
putexcel A44 = "Personal care";
putexcel A45 = "    Normal ability"; 
putexcel A46 = "    Sometimes forgets"; 
putexcel A47 = "Bladder and bowel control";
putexcel A48 = "    Normal control"; 
putexcel A49 = "    Rarely fails to control"; 
putexcel A50 = "    Occasional fails to control"; 
putexcel A51 = "    Frequently fails to control";
putexcel A52 = "Navigation";
putexcel A53 = "    Normal ability"; 
putexcel A54 = "    Can walk alone outside";
foreach l in `letter' {;
putexcel `l'55 = " ",  border(bottom, thin, black);
};
putexcel A55 = "    Can walk short distances alone";
*** Cell data;
*LSPQ;
ttest lspq_reverse_apt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B6 = "`msry1'";
putexcel C6 = "`msry2'"; 
putexcel D6 = (r(p)), nformat(0.000) left;
*DSRS;
ttest dsrs_apt, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B7 = "`msry1'";
putexcel C7 = "`msry2'"; 
putexcel D7 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if race_1_ptr!=.;
putexcel D9 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local P`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = ss[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'9 = "`x`i''";
};
*MEMORY;
tab memory_apt mci_status_pt, matcell(mem) chi2;
putexcel D10 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(10+`j');
local M`i' = mem[1,`i']+mem[2,`i']+mem[3,`i']+mem[4,`i']+mem[5,`i'];
local P`j' = string((mem[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = mem[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*DECISIONS;
tab decisions_apt mci_status_pt, matcell(dec) chi2;
putexcel D16 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(16+`j');
local M`i' = dec[1,`i']+dec[2,`i']+dec[3,`i']+dec[4,`i'];
local P`j' = string((dec[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = dec[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*ORIENTATION TO TIME;
tab orientation_to_time_apt mci_status_pt, matcell(ort) chi2;
putexcel D21 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(21+`j');
local M`i' = ort[1,`i']+ort[2,`i']+ort[3,`i'];
local P`j' = string((ort[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = ort[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*ORIENTATION TO PLACE;
tab orientation_to_place_apt mci_status_pt, matcell(orp) chi2;
putexcel D25 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(25+`j');
local M`i' = orp[1,`i']+orp[2,`i']+orp[3,`i'];
local P`j' = string((orp[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = orp[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*SPEECH AND LANGUAGE;
tab speech_and_language_apt mci_status_pt, matcell(spl) chi2;
putexcel D29 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(29+`j');
local M`i' = spl[1,`i']+spl[2,`i']+spl[3,`i']+spl[4,`i']+spl[5,`i'];
local P`j' = string((spl[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = spl[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*SOCIAL AND COMMUNITY;
tab social_and_community_apt mci_status_pt, matcell(soc) chi2;
putexcel D35 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(35+`j');
local M`i' = soc[1,`i']+soc[2,`i']+soc[3,`i']+soc[4,`i'];
local P`j' = string((soc[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = soc[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*ACTIVITIES; 
tab activities_and_respons_apt mci_status_pt, matcell(act) chi2;
putexcel D40 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(40+`j');
local M`i' = act[1,`i']+act[2,`i']+act[3,`i'];
local P`j' = string((act[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = act[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*PERSONAL CARE;
tab personal_care_apt mci_status_pt, matcell(pc) chi2;
putexcel D44 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/2{;
local num = string(44+`j');
local M`i' = pc[1,`i']+pc[2,`i'];
local P`j' = string((pc[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = pc[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*TOILETING;
tab urination_and_bowels_apt mci_status_pt, matcell(toi) chi2;
putexcel D47 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/4{;
local num = string(47+`j');
local M`i' = toi[1,`i']+toi[2,`i']+toi[3,`i']+toi[4,`i'];
local P`j' = string((toi[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = toi[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*NAVIGATING;
tab place_to_place_apt mci_status_pt, matcell(nav) chi2;
putexcel D52 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/3{;
local num = string(52+`j');
local M`i' = nav[1,`i']+nav[2,`i']+nav[3,`i'];
local P`j' = string((nav[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = nav[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
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
putexcel A3:A4 = "Variable", merge bold top left border(top, thin, black); 
putexcel B3:C3 = "Patient MCI Status", merge bold top left border(top, thin, black); 
putexcel D3:D4 = "p-value", merge bold top left border(top, thin, black);  
putexcel B4 = "No MCI (n=`nnmci')", bold top left; 
putexcel C4 = "MCI (n=`nmci')", bold top left;
putexcel A5:D5 = "Mean (SD)", merge italic left border(top, thin, black); 
putexcel A6 = "Relationship length, years"; 
putexcel A7:D7 = "Count (%)", merge italic left;
putexcel A8 = "Site, UM";
putexcel A9 = "Relationship type";
putexcel A10 = "    Child"; 
putexcel A11 = "    Sibling"; 
putexcel A12 = "    Spouse"; 
putexcel A13 = "    Companion"; 
putexcel A14 = "    Friend"; 
putexcel A15 = "    Parent";
putexcel A16 = "    Other";
putexcel A17 = "Physical interaction";
putexcel A18 = "     Daily, live together";
putexcel A19 = "     Daily, live apart";
putexcel A20 = "     Several times per week";
putexcel A21 = "     Once per week";
putexcel A22 = "     1-3 Times per month";
putexcel A23 = "     <1 Time per month";
putexcel A24 = "Verbal interaction";
putexcel A25 = "     Daily";
putexcel A26 = "     Several times per week";
putexcel A27 = "     Once per week";
putexcel A28 = "     1-3 Times per month";
foreach l in `letter' {;
putexcel `l'29 = " ",  border(bottom, thin, black);
};
putexcel A29 = "     <1 Time per month";
*** Cell data;
*RELATIONSHIP LENGTH;
ttest relationship_yrs_dyad, by(mci_status_pt);
forvalues i=1/2{;
local mry`i' = string(`r(mu_`i')', "%9.1f");
local sry`i' = string(`r(sd_`i')', "%9.1f");
local msry`i' = "`mry`i'' (`sry`i'')";
};
putexcel B6 = "`msry1'";
putexcel C6 = "`msry2'"; 
putexcel D6 = (r(p)), nformat(0.000) left;
*STUDY SITE;
tab site mci_status_pt, matcell(ss) chi2, if complete_dyad==1;
putexcel D8 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
local M`i' = ss[1,`i']+ss[2,`i'];
local P`i' = string((ss[2,`i']/`M`i'')*100, "%9.1f");
local C`i' = ss[2,`i'];
local x`i' = "`C`i'' (`P`i'')";
putexcel `var'8 = "`x`i''";
};
*RELATIONSHIP TYPE;
tab relationship_dyad mci_status_pt, matcell(rt) chi2;
putexcel D9 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/7{;
local num = string(9+`j');
local M`i' = rt[1,`i']+rt[2,`i']+rt[3,`i']+rt[4,`i']+rt[5,`i']+rt[6,`i']+rt[7,`i'];
local P`j' = string((rt[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = rt[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*PHYSICAL INTERACTION;
tab freq_see_dyad mci_status_pt, matcell(fse) chi2;
putexcel D17 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/6{;
local num = string(17+`j');
local M`i' = fse[1,`i']+fse[2,`i']+fse[3,`i']+fse[4,`i']+fse[5,`i']+fse[6,`i'];
local P`j' = string((fse[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = fse[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
*VERBAL INTERACTION; 
tab freq_speak_dyad mci_status_pt, matcell(fsp) chi2;
putexcel D24 = (r(p)), nformat(0.000) left;
local letter "B C";
local numcell : word count `letter';
forvalues i=1/`numcell' {;
local var : word `i' of `letter';
forvalues j=1/5{;
local num = string(24+`j');
local M`i' = fsp[1,`i']+fsp[2,`i']+fsp[3,`i']+fsp[4,`i']+fsp[5,`i'];
local P`j' = string((fsp[`j',`i']/`M`i'')*100, "%9.1f");
local C`j' = fsp[`j',`i'];
local x`j' = "`C`j'' (`P`j'')";
putexcel `var'`num' = "`x`j''";
};
};
};

******************************************************* VISUAL: STROBE DIAGRAM;
****** PREVIOUS DIAGRAM;
mata;
B=xl();
B.load_book("S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ");
B.delete_sheet("STROBE Diagram");
end;

quietly {;
***** CURRENT DIAGRAM MACROS;
putexcel set "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\LSPQ Study\Data Analysis\MCIDeM_AIM2_STUDY3_LSPQ", sheet("STROBE Diagram") modify;
local osmall = ", box margin(small) size(vsmall) justification(left)";
local omain = ", box margin(small)";
local ohoriz = ", orientation(vertical) size(small)";
local bc = ", lwidth(medthick) lcolor(black)";
local bca = ", lwidth(medthick) lcolor(black) mlcolor(black) mlwidth(medthick) msize(medlarge)";

***** CURRENT DIAGRAM NUMBERS;
*** DYADS SCREENED;
local assessed = "190";
*EXCLUDED;
local ne = "54";
local ne_refuse = "37";
local ne_pdem = "6";
local ne_ncog = "5";
local ne_nsp = "3";
local ne_other = "3";
*** DYADS ENROLLED;
local tot = "136";
*ATTRITION;
local attrition = "1";
*EXCLUDED;
local excluded = "0";
*** DYADS ANALYZED;
local analyzed = "135";
*MCI STATUS;
tab mci_status_pt, matcell(mstat) missing;
local nomci = mstat[1,1];
local mci = mstat[2,1];
*COMPLETE;
tab mci_status_pt, matcell(complete) missing, if race_1_pt!=. & race_1_ptr!=.;
local complete_nomci = complete[1,1];
local complete_mci = complete[2,1];
*PT ONLY;
sum mci_status_pt if mci_status_pt==0 & race_1_pt!=. & race_1_ptr==.;
local pto_nomci = `r(N)';
sum mci_status_pt if mci_status_pt==1 & race_1_pt!=. & race_1_ptr==.;
local pto_mci = `r(N)';
*PTR ONLY;
sum mci_status_pt if mci_status_pt==0 & race_1_pt==. & race_1_ptr!=.;
local ptro_nomci = `r(N)';
sum mci_status_pt if mci_status_pt==1 & race_1_pt==. & race_1_ptr!=.;
local ptro_mci = `r(N)';
/* NOTE
Assessed, excluded, eligible & total were obtained using: "tab reason_ineligible 
recruit_status , missing, if pttype==1" after importaing data in the master freeze. 
*/

*** DIAGRAM STRUCTURE;
twoway ///
   pci 5.2 0 5.2 6 `bc' || pci 5.2 6 0 6 `bc' || pci 0 6 0 0 `bc' || pci 0 0 5.2 0 `bc' ///
|| pcarrowi 4.8 3 3.5 3 `bca' ///
|| pcarrowi 4.1 3 4.1 3.35 `bca'  /// 
|| pcarrowi 3.35 3 1.8 3 `bca' ///
|| pcarrowi 2.5 3 2.5 3.35 `bca'  /// 
|| pci 1.65 3 1.2 3 `bca'  ///   
|| pci 1.2 1.58 1.2 4.42 `bc' ///
|| pci 1.2 1.6 0.7 1.6 `bca'  ///
|| pci 1.2 4.4 0.7 4.4 `bca'  ///
, ///
text(4.1 0.3 "IDENTIFICATION" `ohoriz') ///
text(2.5 0.3 "FOLLOW-UP" `ohoriz') ///
text(1.2 0.3 "ANALYSIS" `ohoriz') ///
text(4.8 3 "Dyads screened (n=`assessed')" `omain') ///
text(4.1 4.4 "EXCLUDED (n=`ne')" ///
	"•  `ne_pdem'   Potential dementia" ///
	"•  `ne_nsp'   No study partner" ///
	"•  `ne_ncog'   No cognitive test     " ///
	"•  `ne_refuse' Refused" ///		
	"•  `ne_other'   Other" `osmall') ///
text(3.35 3 "Dyads Enrolled (n=`tot')" `omain') ///
text(2.5 4.4 "ATTRITION (n=`attrition')" ///
	"•  Refused to participate " ///
	"•  Too ill to complete" ///
	"•  Could not locate" ///	
	"•  Deceased" ///
	" " ///
	"EXCLUDED (n=`excluded')" ///
	"•  <65 Years of age" ///
	"•  No cognitive tes " ///
	"•  No English" `osmall') ///
text(1.65 3 "Dyads analyzed (n=`analyzed')" `omain') ///	
text(0.6 1.6 "NO MCI (n=`nomci')" ///
	"•  `complete_nomci' Complete" ///
	"•  `pto_nomci'   Patient only" ///
	"•  `ptro_nomci'   Partner only          " `osmall') ///	
text(0.6 4.4 "MCI (n=`mci')" ///
	"•  `complete_mci' Complete" ///
	"•  `pto_mci'   Patient only" ///
	"•  `ptro_mci'   Partner only          " `osmall') ///	
legend(off) ///
xlabel("") ylabel("") xtitle("") ytitle("") ///
plotregion(lcolor(black)) ///
graphregion(lcolor(black)) xscale(range(0 6)) ///
xsize(2) ysize(3) ///
title("STROBE Diagram");
graph export strobe.png, replace width(852) height(1278);
putexcel A1 = picture(strobe.png);
};

**************************************************************** MODEL BUILDING;
***** MACROS;
local outcome "lspq_reverse_pt lspq_reverse_apt";
local dems_pt "age_pt gender_pt education_pt";
local dems_ptr "age_ptr gender_ptr education_ptr";
local health_pt "phq2_pt adl_pt health_pt moca_pt stroke_pt heart_disease_pt lung_disease_pt cancer_pt arthritis_pt";
local health_ptr "phq2_ptr adl_ptr health_ptr stroke_ptr heart_disease_ptr lung_disease_ptr cancer_ptr arthritis_ptr";
local experience_pt "dementia_cfamily_pt stroke_cfamily_pt heart_attack_cfamily_pt";
local experience_ptr "dementia_cfamily_ptr stroke_cfamily_ptr heart_attack_cfamily_ptr";
local social_pt "marital_statu_pt children_pt children_lives_with_pt children_30_mi_pt";
local dyad "relationship_dyad relationship_yrs_dyad freq_see_dyad freq_speak_dyad";
local race "race_pt race_ptr";
local partner "_pt _apt";

***** SELECTING ZERO INFLATION MODEL;
gen zero_pt = lspq_reverse_pt==0;
sw, pr(0.05): logistic zero_pt mci_status_pt `dems_pt' `dems_ptr' race_pt;
gen zero_apt = lspq_reverse_apt==0;
sw, pr(0.05): logistic zero_apt mci_status_pt `dems_pt' `dems_ptr' race_pt;
/* NOTES
PT SELECTED: race_pt
PTR SELECTED: race_pt
MORE COMPLEX MODELS
gen zero_pt = lspq_reverse_pt==0;
sw, pr(0.05): logistic zero_pt mci_status_pt `dems_pt' `dems_ptr' race_pt `health_pt' `health_ptr' `experience_pt' `experience_ptr' `social_pt' `dyad';
*Selected: race_pt marital_statu_pt;
gen zero_apt = lspq_reverse_apt==0;
sw, pr(0.05): logistic zero_apt mci_status_pt `dems_pt' `dems_ptr' race_pt `health_pt' `health_ptr' `experience_pt' `experience_ptr' `social_pt' `dyad';
*Selected: race_pt health_ptr;
*/

***** METHOD: GVSELECT (BEST SUBSET VARIABLE SELECTION);
local o : word count `outcome';
forvalues i=1/`o' {;
local out : word `i' of `outcome';
*M2 DEMOGRAPHIC;
zinb `out' `dems_pt' `dems_ptr' race_pt site, inflate(race_pt);
gvselect <term> `dems_pt' `dems_ptr' race_pt site : zinb `out' <term>, inflate(race_pt);
*M3 HEALTH STATUS;
zinb `out' `health_pt' `health_ptr' dsrs_quartile_apt, inflate(race_pt);
gvselect <term> `health_pt' `health_ptr' dsrs_quartile_apt : zinb `out' <term>, inflate(race_pt);
*M4 EXPERIENCE;
zinb `out' `experience_pt' `experience_ptr', inflate(race_pt);
gvselect <term> `experience_pt' `experience_ptr' : zinb `out' <term>, inflate(race_pt);
*M5 SUPPORT;
zinb `out' `social_pt' marital_statu_ptr `dyad', inflate(race_pt);
gvselect <term> `social_pt' marital_statu_ptr `dyad' : zinb `out' <term>, inflate(race_pt);
};
/* NOTES 
FINAL MODEL PT
	M1 ZERO ORDER:		mci_status_pt 
	M2 DEMOGRAPHIC: 	M1 + gender_pt race_pt education_pt gender_ptr
	M3 HEALTH STATUS:   M2 + health_ptr	
	M4 EXPERIENCE:		M3 + stroke_cfamily_pt heart_attack_cfamily_pt	
	M5 SOCIAL SUPPORT:  M4 + children_lives_with_pt
FINAL MODEL PTR
	M1 ZERO ORDER:		mci_status_pt 
	M2 DEMOGRAPHIC: 	M1 + education_pt
	M3 HEALTH STATUS:   M2 + stroke_ptr cancer_pt adl_ptr arthritis_pt health_pt	
	M4 EXPERIENCE:		M3 + heart_attack_cfamily_ptr	
	M5 SUPPORT:         M4 + relationship_dyad freq_see_dyad	
*/

*********************************************** ANALYSIS: TREATMENT PREFERENCES;
***** PRIMARY 1;
/*
DV: lspq_reverse_pt
*/

***** SECONDARY 1;
/*
DV: lspq_reverse_apt
*/

***** SECONDARY 2;
/*
DV: lspq_reverse_pt lspq_reverse_apt
*/

***** SENSITIVITY;

***** VISUALIZATION;
hist lspq_reverse_pt , by(race_pt);
hist lspq_reverse_apt , by(race_pt);

************************************************* ANALYSIS: PREFERENCES FOR SDM;
***** SECONDARY 1;
kwallis decision_pt, by(mci_status_pt);
kwallis decision_pt if race_pt==0, by(mci_status_pt);
kwallis decision_pt if race_pt==1, by(mci_status_pt);
/*
DV: decision_pt
IV: mci_status_pt
SV: race_pt
*/

***** SECONDARY 2;
kwallis decision_ptr, by(mci_status_pt);
kwallis decision_ptr if race_pt==0, by(mci_status_pt);
kwallis decision_ptr if race_pt==1, by(mci_status_pt);
/*
DV: decision_ptr
IV: mci_status_pt
SV: race_pt?
*/

***** SENSITIVITY;

**************** ANALYSIS: PREFERENCES FOR SDM IN AMI AND ACUTE ISCHEMIC STROKE;
***** SECONDARY 1;
/*
DV: angioplasty_pt 
    surgery_pt heart_rehab_pt 
	cholesterol_med_pt 
	clotbusting_med_pt 
	sx_on_neck_artery_pt 
	stroke_rehab_pt 
	blood_thinning_med_pt
*/

***** SECONDARY 2;
/*
DV: angioplasty_apt 
    surgery_apt 
	heart_rehab_apt 
	cholesterol_med_apt 
	clotbusting_med_apt 
	sx_on_neck_artery_apt 
	stroke_rehab_apt 
	blood_thinning_med_apt
*/

***** SENSITIVITY;

****************************************************** ANALYSIS: RISK PERCEPTION;
***** SECONDARY 1;
/*
DV: falls_f2yrs_pt 
    heart_attack_f2yrs_pt 
	stroke_f2yrs_pt 
	dementia_f2yrs_pt
IV: mci_status_pt

*/

***** SECONDARY 2;
/*
DV: falls_f2yrs_apt 
	heart_attack_f2yrs_apt 
	stroke_f2yrs_apt 
	dementia_f2yrs_apt
IV: mci_status_pt

*/

***** SENSITIVITY;

/*******************************************************************************
---------------------------------- QUESTIONS -----------------------------------

							\\\ DATA MANAGEMENT ///

1. We specify in analytic plan that having a study parter is an inclusion criterion. 
Should we remove the 5 partners that didn't return a survey? If we keep them, should
we impute some of their personal characteristics (e.g., age, sex, race)?
---
NOTE: People typically filled out the entire survey. Few missing values within 
observed participants. Missingness comes from attrition.
--------------------------------------------------------------------------------
*******************************************************************************/

************************************************************** ANALYTIC DATASET;
save "`outpath'", replace;
capture log close;
