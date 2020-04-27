# Analysis for MCI DeM, Aim 2, Study 3  (April 2020)

* STUDY AIM: Determine the influence of mild cognitive impairment (MCI) on patient and study partner preferences and physician recommendations for acute myocardial infarction and ischemic stroke treatment.
* STUDY POPULATION: Elderly patients with variable MCI status and their study partners (n=135 dyads).
* DEPENDENT VARIABLE: LSPQ score.
* INDEPENDENT VARIABLE: MCI status (MCI vs no MCI)
* MODERATOR VARIABLE: Race (Black vs White) (_remove this line_? See note below.)

Notes: 

* These comments apply to an email from Rachael dated April 23, 2020
* RE: MODERATOR VARIABLE: Race (Black vs White) implies that Race * MCI interaction term should be included, but this
is not the case. 

# Comments/Notes on Rachael's analysis

## LSPQ_PRELIM.xlsx

1. Tables 1,2,3,4 with Patient/Study partner/dyad characteristics by MCI status
    - Clarify Median (IQR). Format should be Median (Q1,Q3)
    - Reverse LSPQ, points may need clarification or we may try to express the results on original LSPQ scale.
    - reporting p-values. See ["How should P values be reported?"](https://support.jmir.org/hc/en-us/articles/360000002012-How-should-P-values-be-reported)
    - provide footnote explaining what test was used to obtain p-values 
2. STROBE diagram
    - Remove 'EXCLUDED (n=0)' category?
    - Our study is cross-sectional. Is it correct to have FOLLOW-UP period in this diagram?

## LSPQ_PRIMARY.xlsx

1. **Tables 1-7**: Results of Zero-inflated negative binomial (ZINB) models
* Two sets of coefficients per model
    - a. Negative binomial component
    - b. Zero-inflated component (interpretation in terms of odds ratios as in logistic regression)
* Interpretation (tentative examples)
    - a. if age for a subject is increased by one year the expected (reversed) LSPQ is increased/decreased by a factor of exp(beta)
    - b. if age for a subject is increased by one year the odds of LSPQ=24 is increased/decreased by a factor of exp(beta)
* In every model _the same_ set of covariates is used for both Negative binomial and Zero-inflated components. This is not necessary, but it should be fine.
* remember that interpretation of coefficients should take into account reversing LSPQ.
* BTW: Is higher (not reversed) LSPQ better?
* exponentiate beta coefficients and lower/upper confidence interval bounds to obtain confidence intreval on transformed scale.
* to assess goodness of fit of the models consider Pearson residual plots 

2. **Plot** in **Patient LSPQ** tab
* Please use the same range of values on y axes

3. NOTES:
* Could you run one of the models (let say model in Table 3) with original (not reversed) LSPQ as the dependent variable to see how beta coefficients
are affected?  I am looking for sign flip of beta coefficients.

## Ancilary analyses (Tables 1-6)

* Variables in Tables 1 -6 are expressed on 5 point likert scale with 5 _ordered_ categories.
* I would present counts and percentages  for the 5 categories, instaed of medians.
* to obtain p-values for an association between variable (MCI Yes/No) and ordinal variables aforementioned above I would follow [Agresti](http://users.stat.ufl.edu/~aa/articles/agresti_1981.pdf)
and use Goodman and Kruskal's gamma test
