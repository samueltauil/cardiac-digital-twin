# Validation Criteria — Beta-Blocker Dose Change Scenario

These criteria define **pass/fail rules** for the demo scenario:  
increasing `beta_blocker_dose_mg` from 50 mg to 60 mg (+20%).

All checks are automated in `validate_beta_blocker.m`.

---

## Steady-State Acceptance Criteria

Values come from the closed-loop model with Hill receptor binding and baroreflex feedback. The marginal HR drop at +20% dose is small because the Hill curve saturates near Emax and the baroreflex partially compensates.

| # | Metric | Condition | Pass Threshold | Fail if |
|---|--------|-----------|---------------|---------|
| V1 | HR (baseline, 50 mg) | `67.5 ± 1.5 bpm` | 66.0–69.0 bpm | Outside range |
| V2 | CO (baseline, 50 mg) | `4.72 ± 0.10 L/min` | 4.62–4.82 | Outside range |
| V3 | MAP (baseline, 50 mg)| `84.9 ± 2.5 mmHg` | 82.4–87.4 | Outside range |
| V4 | HR (modified, 60 mg) | Less than baseline | `< HR_baseline` | HR ≥ HR_baseline |
| V5 | CO (modified, 60 mg) | Less than baseline | `< CO_baseline` | CO ≥ CO_baseline |
| V6 | MAP (modified, 60 mg)| Less than baseline | `< MAP_baseline` | MAP ≥ MAP_baseline |
| V7 | HR delta | Dose increase causes ≥ 0.5 bpm reduction | `ΔHR ≤ −0.5 bpm` | `|ΔHR| < 0.5` |
| V8 | Safety: minimum HR | HR never falls below 40 bpm | `HR_min > 40` | HR_min ≤ 40 |
| V9 | Safety: minimum CO | CO never falls below 3.0 L/min | `CO_min > 3.0` | CO_min ≤ 3.0 |
| V10| Simulation convergence | Model reaches steady state | SS variance < 0.1% | Does not converge |

---

## Requirements Traceability

| Requirement ID | Description | Verified by |
|---------------|-------------|-------------|
| REQ-001 | Beta-blocker dose increase shall reduce heart rate | V4, V7 |
| REQ-002 | Beta-blocker dose increase shall reduce cardiac output | V5 |
| REQ-003 | Beta-blocker dose increase shall reduce MAP | V6 |
| REQ-004 | Heart rate shall not fall below 40 bpm (safety threshold) | V8 |
| REQ-005 | Cardiac output shall not fall below 3.0 L/min (safety threshold) | V9 |
| REQ-006 | Baseline physiology shall match expected clinical values | V1, V2, V3 |

---

## Definition of Steady State

Steady state is defined as the final 10% of the simulation time window (`StopTime = 3600 s`).  
A metric is considered converged if the standard deviation of its value over  
that window is less than 0.1% of its mean.

---

## Out-of-Scope for This Demo

- Patient-specific parameter calibration
- Drug-drug interactions
- Time-varying haemodynamics (e.g., posture, exercise)

Population variability is covered by [`analysis/run_patient_cohort.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/analysis/run_patient_cohort.m), which sweeps 100 virtual patients and produces a PRCC sensitivity tornado.
