# delimit; 
clear all; 
set more off; 
set maxvar 32767;
capture log close;
set seed 993929;
cd "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\2020 Freeze";

/* 
////////////////////////////////////////////////////////////////////////////////
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
************************* DATA MANAGEMENT INFORMATION **************************
MCI DeM Aim 2, Study 3
Data Management syntax file
Deb Levine, MD MPH, University of Michigan
Created by Rachael Whitney, PhD: 01/10/2020
Updated by Rachael Whitney, PhD: 02/06/2020

TASK: Generate a 2020 MCI DeM master file containing patient-partner survey data. 

Variables were renamed using code written by Mohammed Kabeto 
(MCIDEMPatientPartner_surveydata_renaming.do). New variables were created and
data was restructured using code written by Rachael Torres Whitney. 

---INPUT FILES---
MCIDEMPatientSurveys-ExportForAnalysis_DATA_NOHDRS_2020-01-08_0937.csv was imported 
using MCIDEMPatientSurveys-ExportForAnalysis_STATA_2020-01-08_0937.do
and saved as MCIDEMPatientSurveys_STATA_200108.dta. This file contains survey data.

MCIDEMPatientSurveys_DATA_NOHDRS_2020-01-22_1316.csv was imported using 
MCIDEMPatientSurveys_STATA_2020-01-22_1316.do and saved as 
MCIDEMPatientSurveys_STATA_2020-01-22_1316.dta. This file contains data on
patient MCI status and MoCA scores. 

---OUTPUT FILES---
2020 Freeze:     MCIDeM_AIM2_STUDY3_MASTER_200206.dta

********************************************************************************
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
*/

******************************************************************* DATA IMPORT;
*** TRACKER DATA;
quietly{;
use "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\Data from REDCap\Patient Surveys_Mailing & Phone Call Tracking\MCIDEMPatientSurveys_STATA_2020-01-22_1316.dta", clear;
tempfile tracker;
gen lengthst = length(mci_dem_dyadsubject_id);
gen dyadid = substr(mci_dem_dyadsubject_id, 1, lengthst-2);
lab var dyadid "Dyad ID";
*RECODES PATIENT_STATUS
label define mci 0 "No MCI" 1 "MCI";
recode patient_status 2=0;
*ASSIGNS PATIENT MCI STATUS TO PARTNER;
egen x = total(patient_status), by(dyadid) missing;
label values patient_status x mci;
drop patient_status;
rename x patient_status;
keep if eligibility_status==1;
keep mci_dem_dyadsubject_id patient_status moca dyadid cog_assessment_12mo englishspeaking;
save `tracker';
/* NOTE
patient_status indicates patient group assignemnt (0 = No MCI, 1 = MCI). This
variable contained missing values for all study partners, but has been recoded. 
patient_status is now provided by dyadid, so that we can easily determine whether
or not a given study partner is associated with a patient that has normal or 
mildly impaired cognitive function. This code is written in the DATA IMPORT 
section because several patients did not return surveys, and are not included
in the final master dataset. 
*/
};

*** SURVEY DATA;
quietly{;
use "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\Data from REDCap\Patient Surveys_Survey Data\MCIDEMPatientSurveys_STATA_200108.dta", clear;
merge 1:1 mci_dem_dyadsubject_id using `tracker', update;
keep if _merge==3;
drop _merge;
};

*** INCOMPLETE DYAD DATA;
quietly{;
tempfile master; 
save `master';
tempfile incomplete;
*TRACKER DATA;
use "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\Data from REDCap\Patient Surveys_Mailing & Phone Call Tracking\MCIDEMPatientSurveys_STATA_2020-01-22_1316.dta", clear;
gen lengthst = length(mci_dem_dyadsubject_id);
gen dyadid = substr(mci_dem_dyadsubject_id, 1, lengthst-2);
lab var dyadid "Dyad ID";
gen pnid = substr(mci_dem_dyadsubject_id, lengthst-1, lengthst);
keep if eligibility_status==1;
keep if mci_dem_dyadsubject_id=="UMDL195009410" | mci_dem_dyadsubject_id=="UMDL195005120" | mci_dem_dyadsubject_id=="UMDL195002010" | mci_dem_dyadsubject_id=="UMDL1950013810" | mci_dem_dyadsubject_id=="UMDL195003520" | mci_dem_dyadsubject_id=="UMDL195009320" | mci_dem_dyadsubject_id=="UMDL1950010620" | mci_dem_dyadsubject_id=="UMDL195005820";
keep mci_dem_dyadsubject_id sex age sp_age race relationship_sp otherrelationship_specify moca dyadid pnid englishspeaking cog_assessment_12mo;
*MISSING DYAD MEMBER DATA;
rename age f_1_age; 
rename sp_age g_1_age_v2;
rename sex f_2_gender;
gen f_4_race___3 = race==2;
gen f_4_race___5 = race==1;
recode f_4_race___3 f_4_race___5 (0=.) if race==.;
drop race;
rename relationship_sp g_6_relationship;
rename otherrelationship_specify g6a_other_relationship;
save `incomplete';
*ADDS MISSING DYAD MEMBER DATA TO MASTER;
use `master', clear;
append using `incomplete', nolabel;
*GENERATES PATIENT MCI STATUS FOR MISSING PARTNERS;
egen x = total(patient_status), by(dyadid) missing;
replace patient_status = x if patient_status==.;
drop x;
*GENERATES SURVEY TYPE FOR MISSING DYAD MEMBER;
replace patientsurvey = 1 if patientsurvey==. & pnid=="10";
replace studypartnersurvey = 1 if studypartnersurvey==. & pnid=="20";
*GENERATES PATIENT LANGUAGE FOR MISSING DYAD MEMBER;
egen x = total(englishspeaking), by(dyadid) missing;
replace englishspeaking = x if englishspeaking==.;
drop x;
*GENERATES PATIENT COG ASSESSMENT STATUS FOR MISSING DYAD MEMBER;
egen x = total(cog_assessment_12mo), by(dyadid) missing;
replace cog_assessment_12mo = x if cog_assessment_12mo==.;
recode cog_assessment_12mo (. 0=1); /* Error in data entry, checked by Bailey Reale */;
drop x dyadid pnid;
/* NOTE
8 participants are part of an incomplete dyad due to lack of survey data. The 
code above gathers as much information as possible from the tracker about the 
missing members of incomplete dyads. Please note that the tracker contains no 
demographic data for study partners who are part of an incomplete dyad. 

Missing patient: 
	UMDL1950094
	UMDL1950020
	UMDL19500138
Missing partner:
	UMDL1950051
	UMDL1950035
	UMDL1950093
	UMDL19500106
	UMDL1950058
*/
};

************************************************************** VARIABLE RENAMES;
*** RENAMES PATIENT-RESPONSE VARIABLES;
quietly{;
rename  a_1_ch_antibiotics 		ch_antibiotics; 			
rename  a_2_ch_cpr			ch_cpr;              	
rename  a_3_ch_gallbladder          	ch_gallbladder;         	
rename  a_4_ch_artificial_fd        	ch_artificial_fd;       	
rename  a_5_emph_antibiotics 		emph_antibiotics;		
rename  a_6_emph_cpr 			emph_cpr;				
rename  a_7_emph_gallbladder 		emph_gallbladder;		
rename  a_8_emph_artificial_fd 	  	emph_artificial_fd;		
rename  a_9_stroke_antibiotics 	  	stroke_antibiotics;		
rename  a_10_stroke_cpr 		stroke_cpr;	
rename  a_11_stroke_gallbladder 	stroke_gallbladder;		
rename  a_12_stroke_artificial_fd   	stroke_artificial_fd;	
rename  a_13_cancer_antibiotics 	cancer_antibiotics;		
rename  a_14_cancer_cpr 		cancer_cpr;			
rename  a_15_cancer_gallbladder 	cancer_gallbladder;		
rename  a_16_cancer_artificial_fd   	cancer_artificial_fd;	
rename  a_17_hattack_antibiotics 	hattack_antibiotics;		
rename  a_18_hattack_cpr 		hattack_cpr;				
rename  a_19_hattack_gallbladder 	hattack_gallbladder; 	
rename  a_20_hattack_artificial_fd 	hattack_artificial_fd;	
rename  a_21_ad_antibiotics 		ad_antibiotics;			
rename  a_22_ad_cpr 			ad_cpr;					
rename  a_23_ad_gallbladder 		ad_gallbladder;			
rename  a_24_ad_artificial_fd 		ad_artificial_fd;		
rename  b_1_decision 			decision;				
rename  c_1_angioplasty 		angioplasty;				
rename  c_2_surgery 			surgery;				
rename  c_3_heart_rehab 		heart_rehab;				
rename  c_4_cholesterol_med 	    	cholesterol_med;			
rename  c_5_clotbusting_med 		clotbusting_med;			
rename  c_6_sx_on_neck_artery 		sx_on_neck_artery;		
rename  c_7_stroke_rehab 		stroke_rehab;			
rename  c_8_blood_thinning_med 		blood_thinning_med;		
rename  d_1_fall 			falls_f2yrs;				
rename  d_2_heart_attack 		heart_attack_f2yrs;		
rename  d_3_stroke 			stroke_f2yrs;			
rename  d_4_dementia 			dementia_f2yrs;			
rename  e_1_health 			health; 					
rename  e_2_stroke 			stroke;					
rename  e_3_heart_disease 		heart_disease;			
rename  e_4_lung_disease 		lung_disease;				
rename  e_5_cancer 			cancer;					
rename  e_6_arthritis 			arthritis;				
rename  e_7_little_interest 	    	little_interest;			
rename  e_8_depressed 			depressed;				
rename  e_9_walking 			walking;					
rename  e_10_dressing 			dressing;				
rename  e_11_bathing 			bathing;					
rename  e_12_eating 			eating;					
rename  e_13_out_of_bed 		bed;					
rename  e_14_toileting 			toileting;				
rename  f_1_age 			age;						
rename  f_2_gender 			gender;					
rename  f_3_hispanic 			hispanic;				
rename  f_4_race___1 			race_1;					
rename  f_4_race___2 			race_2;				
rename  f_4_race___3 			race_3;				
rename  f_4_race___4 			race_4;				
rename  f_4_race___5 			race_5;				
rename  f_4_race___6 			race_6;				
rename  sec_f_4a_other_race 	    	other_race;				
rename  f_5_marital_status 		marital_statu;			
rename  f_6_children 			children;				
rename  f_7_children_lives_with 	children_lives_with;	
rename  f_8_children_30_mi 		children_30_mi;	
rename  f_9_education 			education;		
rename  f_10_dementia 			dementia_cfamily;		
rename  f_11_stroke 			stroke_cfamily;			
rename  f_12_heart_attack 		heart_attack_cfamily;	
rename  additional_notes 		additional_notes;		
rename  patient_survey_respo_v_0 	survey_complete;
};			

*** RENAMES PARTNER-RESPONSE VARIABLES;
quietly{;
*PARTNER ABOUT PATIENT;
rename  a_1_ch_antibiotics_v2 		ch_antibiotics_abp ;			
rename  a_2_ch_cpr_v2 			ch_cpr_abp;    			
rename  a_3_ch_gallbladder_v2 		ch_gallbladder_abp;         		
rename  a_4_ch_artificial_fd_v2 	ch_artificial_fd_abp;       		
rename  a_5_emph_antibiotics_v2 	emph_antibiotics_abp;				
rename  a_6_emph_cpr_v2 		emph_cpr_abp;				
rename  a_7_emph_gallbladder_v2 	emph_gallbladder_abp;				
rename  a_8_emph_artificial_fd_v2 	emph_artificial_fd_abp;				
rename  a_9_stroke_antibiotics_v2 	stroke_antibiotics_abp;				
rename  a_10_stroke_cpr_v2 		stroke_cpr_abp;						
rename  a_11_stroke_gallbladder_v2 	stroke_gallbladder_abp;				
rename  a_12_stroke_art_fd_v2 		stroke_artificial_fd_abp;			
rename  a_13_cancer_antibiotics_v2 	cancer_antibiotics_abp;				
rename  a_14_cancer_cpr_v2 		cancer_cpr_abp;						
rename  a_15_cancer_gallbladder_v2 	cancer_gallbladder_abp;				
rename  a_16_cancer_art_fd_v2 		cancer_artificial_fd_abp;			
rename  a_17_hattack_antib_v2 		hattack_antibiotics_abp;			
rename  a_18_hattack_cpr_v2 		hattack_cpr_abp;					
rename  a_19_hattack_gallbla_v2 	hattack_gallbladder_abp;			
rename  a_20_hattack_art_fd_v2 		hattack_artificial_fd_abp;			
rename  a_21_ad_antibiotics_v2 		ad_antibiotics_abp;					
rename  a_22_ad_cpr_v2 			ad_cpr_abp;							
rename  a_23_ad_gallbladder_v2 		ad_gallbladder_abp;					
rename  a_24_ad_artificial_fd_v2 	ad_artificial_fd_abp;
rename  c_1_angioplasty_v2 		angioplasty_abp;					
rename  c_2_surgery_v2 			surgery_abp;						
rename  c_3_heart_rehab_v2 		heart_rehab_abp;					
rename  c_4_cholesterol_med_v2 		cholesterol_med_abp;				
rename  c_5_clotbusting_med_v2 		clotbusting_med_abp;				
rename  c_6_sx_on_neck_art_v2 		sx_on_neck_artery_abp;				
rename  c_7_stroke_rehab_v2 		stroke_rehab_abp;					
rename  c_8_blood_thinning_med_v2 	blood_thinning_med_abp;				
rename  d_1_fall_v2 			falls_f2yrs_abp;						
rename  d_2_heart_attack_v2 		heart_attack_f2yrs_abp;				
rename  d_3_stroke_v2 			stroke_f2yrs_abp;					
rename  d_4_dementia_v2 		dementia_f2yrs_abp;					
rename  e_1_memory 			memory_abp;							
rename  e_2_speech_and_language 	speech_and_language_abp;				
rename  e_3_reg_of_fam_members 		reg_of_fam_members_abp;				
rename  e_4_orientation_to_time 	orientation_to_time_abp;				
rename  e_5_orientation_to_place 	orientation_to_place_abp;				
rename  e_6_decisions 			decisions_abp;						
rename  e_7_social_and_community 	social_and_community_abp;				
rename  e_8_activities_and_respons 	activities_and_respons_abp;			
rename  e9_personal_care 		personal_care_abp;					
rename  e10_eating 			eatinglevl_abp;							
rename  e11_urination_and_bowels 	urination_and_bowels_abp;				
rename  e12_place_to_place 		place_to_place_abp;

*PARTNER ABOUT SELF;
rename  b_1_decision_v2 		decision_pr;
rename  f1_health 			health_pr;							
rename  f2_stroke 			stroke_pr;							
rename  f3_heart_disease 		heart_disease_pr;					
rename  f4_lung_disease 		lung_disease_pr;						
rename  f5_cancer 			cancer_pr;							
rename  f6_arthritis 			arthritis_pr;						
rename  f7_little_interest 		little_interest_pr;					
rename  f8_depressed 			depressed_pr;						
rename  f_9_walking_v2 			walking_pr;							
rename  f_10_dressing_v2 		dressing_pr;						
rename  f_11_bathing_v2 		bathing_pr;						
rename  f_12_eating_v2 			eating_pr;						
rename  f_13_out_of_bed_v2 		bed_pr;						
rename  f_14_toileting_v2 		toileting_pr;
rename  g_1_age_v2 			age_pr;								
rename  g_2_gender_v2 			gender_pr;							
rename  g_3_hispanic_v2 		hispanic_pr;						
rename  g_4_race_v2___1 		race_1_pr;						
rename  g_4_race_v2___2 		race_2_pr;							
rename  g_4_race_v2___3 		race_3_pr;						
rename  g_4_race_v2___4 		race_4_pr;							
rename  g_4_race_v2___5 		race_5_pr;							
rename  g_4_race_v2___6 		race_6_pr;							
rename  sec_g_4a_other_race_v2 		other_race_pr;						
rename  g_5_marital_status_v2 		marital_statu_pr;					
rename  g_6_relationship 		relationship_pr;						
rename  g6a_other_relationship 		other_relationship_pr;				
rename  g_7_relationship_yrs 		relationship_yrs_pr;					
rename  g_8_frequency_seen 		frequency_seen_pr;					
rename  other_freq 			other_freq_pr;
rename  g_9_speak_with 			speak_with_pr;						
rename  g9a_freq_spoken_to 		freq_spoken_t_pr;					
rename  g_10_education_v2 		education_pr;					
rename  g_11_dementia_v2 		dementia_cfamily_pr;					
rename  g_12_stroke_v2 			stroke_cfamily_pr;				
rename  g_13_heart_attack_v2 		heart_attack_cfamily_pr;	
rename  additional_notes_v2 		additional_notes_pr;					
rename  study_partner_survey_v_1 	survey_complete_pr;
};

***************************************************************** NEW VARIABLES;
*** PARTICIPANT & DYAD IDENTIFIERS;
quietly{;
gen str14 dyadsubjid = mci_dem_dyadsubject_id; 
gen lengthst = length(mci_dem_dyadsubject_id);
gen dyadid = substr(mci_dem_dyadsubject_id, 1, lengthst-2);
lab var dyadid "Dyad ID";
gen pnid = substr(mci_dem_dyadsubject_id, lengthst-1, lengthst);
lab var pnid "Person Number ID";
gen site = substr(mci_dem_dyadsubject_id, 1, 4);
lab var site "Study site";
drop lengthst mci_dem_dyadsubject_id;
};

*** PARTICIPANT TYPE IDENTIFIER; 
quietly{;
gen pttype = 0 if patientsurvey==1;
replace pttype = 1 if studypartnersurvey==1;
lab var pttype "Participant Type";
lab define pt 0 "Patient" 1 "Partner";
lab values pttype pt;
replace pttype = 0 if age!=. & age_pr==. & pttype==.;
replace pttype = 1 if age==. & age_pr!=. & pttype==.;
drop pnid redcap_data_access_group patientsurvey;
};

*** COMPLETE DYAD;
quietly{;
egen complete_dyad = count(new_c7_c8_study_part_v_2), by(dyadid);
recode complete_dyad (1=0) (2=1);
/* NOTE
Not all participants were part of a complete dyad, due to some failing to return
the survey. This variable identifies dyads as being incomplete (complete_dyad=0)
or complete (complete_dyad=1).
*/
};

*** RACE;
quietly{;
*PATIENT ABOUT SELF;
label define race 1 "Black" 0 "White" 2 "Other"; 
gen race = 1 if race_3==1;
replace race = 0 if race_5==1 & race==.;
replace race = 2 if race_1==1 & race==. | race_2==1 & race==. | race_4==1 & race==. | race_6==1 & race==.;
replace race = 0 if race_6==1 & other_race=="Minority White";
label values race race;
*PARTNER ABOUT SELF;
gen race_pr = 1 if race_3_pr==1;
replace race_pr = 0 if race_5_pr==1 & race_pr==.;
replace race_pr = 2 if race_1_pr==1 & race_pr==. | race_2_pr==1 & race_pr==. | race_4_pr==1 & race_pr==. | race_6_pr==1 & race_pr==.;
label values race_pr race;
/* NOTE
Race categories identified are White (race=0), Black (race=1) and Other (race=2).
Some participants selected more than two races. Participants who identified as 
Black and another race were categorized as Black. One patient (UMDL1950010710)
identified as "other race", which was further described as "Minority White" in 
the survey. In the tracker, this participant identified as White. This patient is
thus categorized as White in the master file.
*/
};

*** DEPRESSED MOOD;
quietly{;
*PATIENT ABOUT SELF;
egen phq2 = rowtotal(depressed little_interest), missing, if pttype==0;
replace phq2 = phq2-2;
*PARTNER ABOUT SELF;
egen phq2_pr = rowtotal(depressed_pr little_interest_pr), missing, if pttype==1;
replace phq2_pr = phq2_pr-2;
/* NOTE
depressed & little_interest take the values 1 to 4, but should take the values of
0 to 3 in order to calculate PHQ-2 (a scale with values ranging from 0 to 6). To
account for this, two points are subtracted from the PHQ-2 score calculated above. 
All participants have non-missing values for depressed and little_interest. PHQ-2
scores ranging from 3-6 indicate depressed mood;
*/
};

*** ADL LIMITATIONS;
quietly{;
local adls "walking dressing bathing eating bed toileting walking_pr dressing_pr bathing_pr eating_pr bed_pr toileting_pr";
label define adl 1 "Difficulty" 0 "No difficulty";
foreach var in `adls'{;
recode `var' (2=0);
label values `var' adl;
};
*PATIENT ABOUT SELF;
egen adl = rowtotal(walking dressing bathing eating bed toileting), missing, if pttype==0;
*PARTNER ABOUT SELF;
egen adl_pr = rowtotal(walking_pr dressing_pr bathing_pr eating_pr bed_pr toileting_pr), missing, if pttype==1;
/* NOTE
The Activities of Daily Living (ADL) score assesses the level of difficulty an 
individual has performing six standard activities: walking, dressing, bathing, 
eating, getting into/out of bed and toileting. ADL score is calculated using 
the HRS-method, in which activity-specific variables are recoded (0 = Has no
difficulty, 1 = Has difficulty) and totaled. Higher scores indicate greater 
difficulty performing standard activities of daily living.
*/
};

*** LSPQ SCORE;
quietly{;
*PATIENT ABOUT SELF;
tempfile master;
save `master';
tempfile lspq;
local plspq "ch_antibiotics ch_cpr ch_gallbladder ch_artificial_fd emph_antibiotics emph_cpr emph_gallbladder emph_artificial_fd stroke_antibiotics stroke_cpr stroke_gallbladder stroke_artificial_fd cancer_antibiotics cancer_cpr cancer_gallbladder 	cancer_artificial_fd hattack_antibiotics hattack_cpr hattack_gallbladder hattack_artificial_fd ad_antibiotics ad_cpr ad_gallbladder ad_artificial_fd";
foreach p in `plspq' {;
recode `p' (1 2 3 = 1) (4 5 = 0);
label define `p' 1 "Want treatment" 0 "Don't want treatment";
label values `p' `p';
};
egen lspq = rowtotal(`plspq'), missing, if pttype==0;
*PARTNER ABOUT PATIENT;
local splspq "ch_antibiotics_abp ch_cpr_abp ch_gallbladder_abp ch_artificial_fd_abp emph_antibiotics_abp emph_cpr_abp emph_gallbladder_abp emph_artificial_fd_abp stroke_antibiotics_abp stroke_cpr_abp stroke_gallbladder_abp stroke_artificial_fd_abp cancer_antibiotics_abp cancer_cpr_abp cancer_gallbladder_abp cancer_artificial_fd_abp hattack_antibiotics_abp hattack_cpr_abp hattack_gallbladder_abp hattack_artificial_fd_abp ad_antibiotics_abp ad_cpr_abp ad_gallbladder_abp ad_artificial_fd_abp";
foreach s in `splspq' {;
recode `s' (1 2 3 = 1) (4 5 = 0);
label define `s' 1 "Want treatment" 0 "Don't want treatment";
label values `s' `s';
};
egen lspq_abp = rowtotal(`splspq'), missing, if pttype==1;
keep dyadsubjid lspq lspq_abp;
save `lspq';
use `master';
merge 1:1 dyadsubjid using `lspq', nogenerate;
/* NOTE
The Life-Support Preferences Predicitions Questionnaire (LSPQ) assesses patient
treatment preferences across a broad spectrum of life-sustaining treatment
decisions varying in invasiveness: antibiotics, cardiopulmonary resuscitation, 
gallbladder surgery and artificial nutrition and hydration. Decisions are made
in the context of the following medical scenarios: current health, Alzhiemer's
disease, emphysema, stroke, cancer and MI. LSPQ score is calculated by recoding
decision-specific variables (0 = Do not want treatment, 1 = Want treatment) and
totaling them. Higher scores indicate greater desire for treatment.
*/
};

*** DSRS SCORE;
quietly{;
*PARTNER ABOUT PATIENT;
egen dsrs_abp = rowtotal(memory_abp speech_and_language_abp reg_of_fam_members_abp orientation_to_time_abp orientation_to_place_abp decisions_abp social_and_community_abp activities_and_respons_abp personal_care_abp eatinglevl_abp urination_and_bowels_abp place_to_place_abp), missing, if pttype==1;
/* NOTE
The Dementia Severity Rating Scale (DSRS) is an informant-rated questionnaire
that assesses the functional abilities of persons undergoing dementia evaluation. 
DSRS score is calculated by totaling the informant's responses to 12 questions. 
*/
};

*** QUICK FIXES;
quietly{;
drop stroke_rehab_abp blood_thinning_med_abp; /* Survey issue: fixed variables are new_c7 and new_c8 */;
rename new_c7 stroke_rehab_abp;
rename new_c8 blood_thinning_med_abp;
order dyadsubjid dyadid site pttype patient_status *;
forvalues i=1/6 {;
replace race_`i' = . if pttype==1;
replace race_`i'_pr = . if pttype==0;
};
};

************************************************************** DATA RESTRUCTURE;
*** PATIENT-SPECIFIC RESPONSES: _PT SUFFIX;
quietly{;
local ptvars "ch_antibiotics ch_cpr ch_gallbladder ch_artificial_fd emph_antibiotics emph_cpr emph_gallbladder emph_artificial_fd stroke_antibiotics stroke_cpr stroke_gallbladder stroke_artificial_fd cancer_antibiotics cancer_cpr cancer_gallbladder cancer_artificial_fd hattack_antibiotics hattack_cpr hattack_gallbladder hattack_artificial_fd ad_antibiotics ad_cpr ad_gallbladder ad_artificial_fd decision angioplasty surgery heart_rehab cholesterol_med clotbusting_med sx_on_neck_artery stroke_rehab blood_thinning_med falls_f2yrs heart_attack_f2yrs stroke_f2yrs dementia_f2yrs health stroke heart_disease lung_disease cancer arthritis little_interest depressed walking dressing bathing eating bed toileting age gender race_1 race_2 race_3 race_4 race_5 race_6 marital_statu children children_lives_with children_30_mi education dementia_cfamily stroke_cfamily heart_attack_cfamily moca race phq2 adl lspq hispanic cog_assessment_12mo englishspeaking";
foreach var in `ptvars' {;
egen x = total(`var'), by(dyadid) missing;
drop `var';
rename x `var'_pt;
};
};

*** PARTNER-SPECIFIC RESPONSES: _PTR SUFFIX;
quietly{;
local ptrvars "marital_statu race_5 race_6 race_4 race_3 race_2 race_1 hispanic gender heart_attack_cfamily stroke_cfamily dementia_cfamily education age walking depressed little_interest arthritis cancer lung_disease heart_disease stroke toileting bed eating bathing dressing health decision race adl phq2";
foreach var in `ptrvars' {;
egen x = total(`var'_pr), by(dyadid) missing;
drop `var'_pr;
rename x `var'_ptr;
};
};

*** PARTNER-SPECIFIC RESPONSES ABOUT PATIENT: _APT SUFFIX;
quietly{;
local aptvars "ch_antibiotics ch_cpr ch_gallbladder ch_artificial_fd emph_antibiotics emph_cpr emph_gallbladder emph_artificial_fd stroke_antibiotics stroke_cpr stroke_gallbladder stroke_artificial_fd cancer_antibiotics cancer_cpr cancer_gallbladder cancer_artificial_fd hattack_antibiotics hattack_cpr hattack_gallbladder hattack_artificial_fd ad_antibiotics ad_cpr ad_gallbladder ad_artificial_fd angioplasty surgery heart_rehab cholesterol_med clotbusting_med sx_on_neck_artery stroke_rehab blood_thinning_med falls_f2yrs heart_attack_f2yrs stroke_f2yrs dementia_f2yrs memory speech_and_language reg_of_fam_members orientation_to_time orientation_to_place decisions social_and_community activities_and_respons personal_care eatinglevl urination_and_bowels place_to_place lspq dsrs";
foreach var in `aptvars' {;
egen x = total(`var'_abp), by(dyadid) missing;
drop `var'_abp;
rename x `var'_apt;
};
};

*** PARTNER-SPECIFIC RESPONSES ABOUT DYAD: _DYAD SUFFIX;
quietly{;
local dyad "relationship relationship_yrs frequency_seen speak_with";
foreach d in `dyad' {;
replace `d'_pr = . if pttype==0;
egen x = total(`d'_pr), by(dyadid) missing;
drop `d'_pr;
rename x `d'_dyad;
};
};

************************************************************** VARIABLE RECODES;
*** _PT & _PTR VARIABLES;
quietly{;
local type1 "pt ptr";
local type2 "pt apt";
foreach t in `type1'{;
*MEDICAL HISTORY;
recode stroke_`t' heart_disease_`t' lung_disease_`t' arthritis_`t' cancer_`t' (2=0);
*GENDER;
recode gender_`t' (2=0);
*HISPANIC RACE;
recode hispanic_`t' (2=0);
*DEPRESSED MOOD;
recode depressed_`t' little_interest_`t' (1=0) (2=1) (3=2) (4=3);
*FAMILY HISTORY;
recode dementia_cfamily_`t' stroke_cfamily_`t' heart_attack_cfamily_`t' (2=0);
};
};

*** _PT VARIABLES ONLY;
quietly{;
*CHILDREN;
recode children_pt children_30_mi_pt children_lives_with_pt (2=0);
*LANGUAGE AND COG ASSESSMENT;
recode englishspeaking_pt cog_assessment_12mo_pt (2=1);
};

*** _DYAD VARIABLES; 
quietly{;
*RELATIONSHIP;
recode relationship_dyad (8=1) (9=2) (10=3) (11=4) (12=5) (13=6) (16=7);
replace relationship_dyad = 6 if other_relationship_pr=="Friend and church member";
replace relationship_dyad = 2 if other_relationship_pr=="We are partners, but do not live together at this time.";
/* NOTE: "Other" relationships are described as: girlfriend, aunt, cousin, granddaughter or neice */;
*SPEAKING INTERACTION;
recode speak_with_dyad (7=5) (8=6);
replace speak_with_dyad = 1 if freq_spoken_t_pr=="I live with the person"; 
replace speak_with_dyad = 1 if frequency_seen_dyad==1 | frequency_seen_dyad==2;
replace speak_with_dyad = 2 if frequency_seen_dyad==3 & speak_with_dyad==6;
replace speak_with_dyad = 3 if frequency_seen_dyad==4 & speak_with_dyad==6;
replace speak_with_dyad = 4 if freq_spoken_t_pr=="family functions, funerals, weddings";
};

*** UNNECESSARY VARIABLES;
quietly{; 
drop freq_spoken_t_pr other_relationship_pr survey_complete survey_complete* other_race* additional_notes* new_date new_c7_c8_study_part_v_2; /* Not informative */;
drop other_freq_pr; /* Contains only missing values */;
drop *studypartnersurvey; /* Duplicate variable */;
};

************************************************************* VARIABLE RELABELS;
*** _PT & _PTR VARIABLES;
quietly{;
label define dsdm 1 "I make decision" 2 "I make final decision" 3 "My doctor and I make decision" 4 "My doctor makes final decision" 5 "My doctor makes decision";
label define education 1 "8th grade or less" 2 "Some high school" 3 "High school graduate or GED" 4 "Trade school" 5 "Some college or 2-year degree" 6 "4-year degree" 7 "Graduate degree";
label define marital 1 "Married " 2 "Live with partner" 3 "Divorced or separated" 4 "Widowed" 5 "Never married";
label define phq 0 "Not at all" 1 "Several days" 2 "More than half the days" 3 "Nearly every day";
label define health 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair";
label define gender 0 "Female" 1 "Male";
label define history 0 "No" 1 "Yes";
local adl "walking dressing bathing eating bed toileting";
local fhistory "dementia_cfamily stroke_cfamily heart_attack_cfamily";
local history "stroke heart_disease lung_disease cancer arthritis";
local phq "little_interest depressed";
foreach t in `type1'{;
*DEGNER SDM;
label values decision_`t';
label values decision_`t' dsdm;
*SELF-RATED HEALTH;
label values health_`t';
label values health_`t' health;
*MEDICAL HISTORY;
foreach var in `history' {;
label values `var'_`t';
label values `var'_`t' history;
};
*GENDER;
label values gender_`t';
label values gender_`t' gender;
*RACE;
label values race_`t' race;
*HISPANIC RACE;
label values hispanic_`t' history;
*ADLS;
foreach var in `adl'{;
label values `var'_`t';
label values `var'_`t' adl;
};
*DEPRESSED MOOD;
foreach var in `phq'{;
label values `var'_`t';
label values `var'_`t' phq;
};
*MARITAL STATUS;
label values marital_statu_`t';
label values marital_statu_`t' marital;
*EDUCATION;
label values education_`t';
label values education_`t' education;
*FAMILY HISTORY;
foreach var in `fhistory'{;
label values `var'_`t';
label values `var'_`t' history;
};
};
};

*** _PT & _APT VARIABLES;
quietly{;
label define risk 1 "Disagree strongly" 2 "Disagree" 3 "Neither agree nor disagree" 4 "Agree" 5 "Agree strongly";
label define care 1 "Definitely want" 2 "Probably want" 3 "Unsure" 4 "Probably do not want" 5 "Definitely do not want";
local lspq "antibiotics cpr gallbladder artificial_fd";
local disease "ch emph stroke cancer hattack ad"; 
local sdm "angioplasty surgery heart_rehab cholesterol_med clotbusting_med sx_on_neck_artery stroke_rehab blood_thinning_med";
local risk "falls_f2yrs heart_attack_f2yrs stroke_f2yrs dementia_f2yrs";
foreach t in `type2'{;
*LSPQ;
foreach d in `disease' {;
foreach var in `lspq' {;
label values `d'_`var'_`t' care;
};
};
*SDM IN AMI, STROKE;
foreach var in `sdm' {;
label values `var'_`t';
label values `var'_`t' care;
};
*RISK PERCEPTION;
foreach var in `risk' {;
label values `var'_`t';
label values `var'_`t' risk;
};
};
};

*** _PT VARIABLES ONLY;
quietly{;
*MCI STATUS;
rename patient_status mci_status_pt;
label define mci 0 "No MCI" 1 "MCI";
label values mci_status_pt mci;
*CHILDREN;
label define children 0 "No" 1 "Yes";
local children "children_pt children_30_mi_pt children_lives_with_pt";
foreach var in `children' {;
label values `var';
label values `var' children;
};
*LANGUAGE AND COG ASSESSMENT;
label define yn 0 "no" 1 "yes";
label values englishspeaking_pt yn;
label values cog_assessment_12mo_pt yn;
};

*** _APT VARIABLES ONLY;
quietly{;
label define memory_apt 1 "Normal memory" 2 "Occasionally forgets" 3 "Mild consistent forgetfulness" 4 "Moderate memory loss" 5 "Substantial memory loss" 6 "Cannot remember basic facts" 7 "Cannot remember most basic things"; 
label values memory_apt memory_apt;
label define speech_and_language_apt 1 "Normal language" 2 "Sometimes cannot find word" 3 "Often forgets words" 4 "Rarely starts conversations" 5 "Hard to understand" 6 "Cannot answer questions" 7 "Does not respond"; 
label values speech_and_language_apt speech_and_language_apt; 
label define reg_of_fam_members_apt 1 "Normal recognition" 2 "Usually recognizes relatives" 3 "Usually cannot recognize relatives" 4 "Sometimes cannot recognize close family" 5 "Frequently cannot recognize caregiver" 6 "No recognition of others"; 
label values reg_of_fam_members_apt reg_of_fam_members_apt;
label define orientation_to_time_apt 1 "Normal awareness" 2 "Some confusion" 3 "Frequently confused about time" 4 "Usually confused about time" 5 "Completely unaware of time";
label values orientation_to_time_apt orientation_to_time_apt; 
label define orientation_to_place_apt 1 "Normal awareness" 2 "Sometimes disoriented" 3 "Frequently disoriented" 4 "Usually disoriented" 5 "Almost always confused";
label values orientation_to_place_apt orientation_to_place_apt; 
label define decisions_apt 1 "Normal" 2 "Some difficulty" 3 "Moderate difficulty" 4 "Rarely makes decisions" 5 "Unaware of what is happening";
label values decisions_apt decisions_apt; 
label define social_and_community_apt 1 "Normal" 2 "Mild problems" 3 "Can participate without help" 4 "Cannot participate without help" 5 "Only interacts with caregiver" 6 "Cannot interact with caregiver";
label values social_and_community_apt social_and_community_apt;
label define activities_and_respons_apt 1 "Normal" 2 "Trouble with difficult tasks" 3 "Trouble with easy tasks" 4 "Cannot perform tasks without help" 5 "No longer performs tasks"; 
label values activities_and_respons_apt activities_and_respons_apt; 
label define personal_care_apt 1 "Normal" 2 "Sometimes forgets" 3 "Requires help" 4 "Totally dependent on help";
label values personal_care_apt personal_care_apt; 
label define eatinglevl_apt 1 "Normal" 2 "Sometimes needs help" 3 "Requires help" 4 "Totally dependent on help";
label values eatinglevl_apt eatinglevl_apt; 
label define urination_and_bowels_apt 1 "Normal" 2 "Rarely fails to control" 3 "Occasional failure to control." 4 "Frequently fails to control." 5 "Generally fails to control";
label values urination_and_bowels_apt urination_and_bowels_apt;
label define place_to_place_apt 1 "Normal" 2 "Can to walk alone outside" 3 "Can walk alone outside for short distances" 4 "Cannot be left outside alone" 5 "Gets confused around the house" 6 "Almost always in a bed or chair" 7 "Always in bed";
label values place_to_place_apt place_to_place_apt;
};

*** DYAD VARIABLES; 
quietly{;
local dyad "relationship_dyad frequency_seen speak_with";
foreach var in `dyad' {;
label values `var';
};
*RELATIONSHIP;
label define relation 1 "Companion" 2 "Spouse" 3 "Child" 4 "Sibling" 5 "Parent" 6 "Friend" 7 "Other";
label values relationship_dyad relation;
*FACE-TO-FACE-INTERACTION;
label define see 1 "I live with the person" 2 "Daily" 3 "Several times a week" 4 "Once a week" 5 "One to three times a month" 6 "Less than once a month";
label values frequency_seen_dyad see;
rename frequency_seen_dyad freq_see_dyad;
*SPEAKING INTERACTION;
label define speak 1 "Daily" 2 "Several times a week" 3 "Once a week" 4 "One to three times a month" 5 "Less than once a month" 6 "Not applicable";
label values speak_with_dyad speak;
rename speak_with_dyad freq_speak_dyad;
};

*** QUICK FIXES;
quietly {;
order dyadsubjid dyadid site pttype mci_status_pt *_pt *_ptr *_apt *_dyad;
duplicates drop dyadid, force; /* Transforms to a wide file, by dyadid */
drop pttype dyadsubjid; /* Unnecessary with this format */
};

********* 2020 MCI DeM AIM 2 STUDY 3 MASTER FREEZE;
save "S:\Intmed_Rsrch2\GenMed\Restricted\MCI DeM\Study 3\Data Analysis\2020 Freeze\MCIDeM_AIM2_STUDY3_MASTER_200206.dta", replace;
