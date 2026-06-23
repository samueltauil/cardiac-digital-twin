---
description: Optional deep-dive step 11 of the cardiac digital twin demo — virtual patient cohort with PRCC sensitivity
---

A nominal patient is a starting point, not a population. Run the
Monte Carlo cohort wrapper in analysis/run_patient_cohort.m. It
samples 100 virtual patients with log-normal PK and Hill parameters
and normal physiology parameters around the nominal values, then
runs each patient at both 50 mg and 60 mg using parsim. Then run
analysis/sensitivity_tornado.m to compute the PRCC sensitivity tornado
against HR at 60 mg and tell me which parameters dominate.
