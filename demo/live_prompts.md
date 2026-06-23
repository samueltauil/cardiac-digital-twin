# Live Demo — Copilot Prompt Sequence

**Scenario:** A cardiologist asks an AI engineering assistant to simulate the effect  
of increasing a patient's beta-blocker (metoprolol) dosage by 20%.

**Delivery:** Copy each prompt exactly into the Copilot Agent chat. Wait for the full  
response before proceeding to the next prompt.

**Fallback:** If any step fails or takes >30 seconds, switch to `scripted_runbook.md`.

---

## Prompt 1 — Explore the Model Architecture

```
I have a cardiac digital twin model open in Simulink called CardiacDigitalTwin.
Give me an overview of the model structure: what are the main subsystems,
what does each one represent, and how do they connect to each other?
```

**Expected MCP tools:** `model_overview`, `model_read`  
**Expected response:** Description of 4 subsystems — BetaBlockerPK, HeartRateModel,  
CardiacOutputModel, BloodPressureModel — and how they form a signal chain  
from drug dose to haemodynamic outputs.

**Narrative bridge (speak aloud):**  
*"So Copilot has just read the entire model architecture — four interconnected  
physiological subsystems, each representing a real clinical mechanism. It didn't  
need documentation. It read the model directly."*

---

## Prompt 2 — Locate the Dosage Parameter

```
I want to change the beta-blocker dose. Find the parameter that controls
the current metoprolol dosage, tell me its current value and units,
and explain how it flows through the model to affect heart rate.
```

**Expected MCP tools:** `model_query_params`, `model_resolve_params`  
**Expected response:** `beta_blocker_dose_mg = 50 mg`; explanation that the dose feeds  
the `BetaBlockerPK` first-order transfer function, which produces plasma concentration,  
which reduces HR through the `HillEquation` block (Emax = 18 bpm, EC50 = 35 mg, Hill n = 1.5).

**Narrative bridge:**  
*"In seconds, Copilot traced the causal pathway from drug dose to heart rate —  
that's the kind of model understanding that would normally take a new engineer  
weeks to build."*

---

## Prompt 3 — Apply the Dose Change

```
Increase the beta_blocker_dose_mg parameter by 20% (from 50 mg to 60 mg).
Make the change in the model and confirm the updated value.
```

**Expected MCP tools:** `model_edit`  
**Expected response:** Confirmation that `BetaBlockerDose` block `Value` was updated  
to `60`; new value verified.

**Narrative bridge:**  
*"One prompt. The model has been updated. A change that would normally go through  
a design review process, a parameter spreadsheet, and a manual edit — done safely  
and traceably by the AI assistant."*

---

## Prompt 4 — Run the Simulation and Compare

```
Run the simulation with the updated 60 mg dose. Then compare the steady-state
results to the baseline (50 mg) for heart rate, cardiac output,
and mean arterial pressure. Present the results in a clear table.
```

**Expected MCP tools:** `model_test` or direct simulation invocation  
**Expected response:** A comparison table showing:

| Metric | Baseline (50 mg) | Modified (60 mg) | Change |
|--------|-----------------|-----------------|--------|
| Heart Rate | ~67.4 bpm | ~66.6 bpm | -1.3% |
| Cardiac Output | ~4.72 L/min | ~4.66 L/min | -1.3% |
| Mean Art. Pressure | ~84.9 mmHg | ~83.9 mmHg | -1.3% |

**Narrative bridge:**  
*"The simulation ran. The marginal drop is small (about 0.9 bpm) because
the Hill receptor binding is saturating near Emax and the baroreflex is
partially compensating. All three haemodynamic metrics moved in the
expected direction, but a clinician would note that pushing the dose
further will give diminishing returns."*

---

## Prompt 5 — Interpret the Clinical Impact

```
Based on the simulation results, explain the clinical significance of this
dose change for a patient with hypertension. Is the new heart rate and
blood pressure within a safe and therapeutically beneficial range?
What would you flag for the cardiologist's attention?
```

**Expected MCP tools:** None (reasoning from prior context)  
**Expected response:** Summary noting:
- HR reduction of ~0.9 bpm is modest. The closed-loop baroreflex absorbs most of the drug's direct effect, and the Hill curve is past EC50 so each extra milligram gives diminishing returns
- MAP reduction of ~1 mmHg contributes a small step toward the antihypertensive goal
- HR at ~66.6 bpm is comfortably above the bradycardia threshold (<50 bpm)
- Cardiac output remains adequate (~4.66 L/min, well above the ~3 L/min concern threshold)
- Flag: dose escalation past EC50 (~35 mg-equivalent concentration) gives shrinking marginal benefit; consider switching agents or adding a second-line therapy before further dose increases

**Narrative bridge:**  
*"This is where it gets powerful. Copilot doesn't just run the simulation —  
it interprets the results in clinical context. It gives the cardiologist  
an immediate, evidence-based summary ready for the patient record."*

---

## Prompt 6 — Generate a Validation Test

```
Write a Gherkin-style test scenario that verifies the cardiac model
correctly shows a reduction in heart rate when beta-blocker dose is
increased from 50 mg to 60 mg. The test should drive the
HeartRateModel subsystem in open-loop (BaroreflexIn held at zero) and
check that the Hill saturated response still produces a measurable
HR drop of at least 0.5 bpm.
```

**Expected MCP tools:** `model_test` (Gherkin test generation)  
**Expected response:** A Gherkin scenario such as:

```gherkin
Feature: Beta-blocker dose-response validation

  Scenario: Increased metoprolol dose reduces heart rate (open loop)
    Given the HeartRateModel is driven with Concentration = const(50)
    And BaroreflexIn is held at const(0)
    When the subsystem reaches steady state
    Then the steady-state heart rate should be near 63.6 bpm
    When Concentration is increased to const(60)
    Then the steady-state heart rate should drop by at least 0.5 bpm
    And the new steady-state heart rate should remain above 40 bpm
```

**Closing narrative:**  
*"In six prompts, GitHub Copilot has acted as a full AI engineering assistant:  
it understood the model, found the parameter, made the change, ran the  
simulation, interpreted the physiology, and generated a verification test.  
This is the future of regulated engineering workflows."*

---

## Prompt 7 — Generate Formal Engineering Requirements

```
Based on the simulation results and the validated dose-response behaviour,
generate formal engineering requirements for this cardiac digital twin model.
Include a system-level requirement for the beta-blocker dose-response,
a performance requirement for steady-state heart rate, and a safety requirement
for the minimum acceptable cardiac output.
```

**Expected skill:** `generate-requirement-drafts`  
**Expected MCP tools:** None (reasoning from prior simulation context)  
**Expected response:** Structured requirements in a standard format, for example:

```
REQ-001 [System]: The cardiac digital twin shall simulate the steady-state
haemodynamic response to a change in beta_blocker_dose_mg within ±5% of
the analytically predicted values.

REQ-002 [Performance]: For beta_blocker_dose_mg in the range [40, 80] mg,
the model shall produce a steady-state heart rate between 40 bpm and 100 bpm.

REQ-003 [Safety]: The model shall flag a warning when simulated cardiac output
falls below 3.0 L/min, indicating a clinically significant risk of inadequate
perfusion.
```

**Closing narrative:**  
*"In seven prompts, we went from an unexplored model to a fully traced engineering  
artefact. Copilot explored the architecture, found the parameter, applied the  
change, ran and compared simulations, interpreted the physiology, wrote the  
verification test, and now generated formal requirements — all from natural  
language, all driven by the live model. This is what AI-assisted model-based  
development looks like."*

---

## Prompt 8 — Real-Time Dashboard (Optional Visual Closer)

```
Launch a real-time dashboard that runs both the 50 mg baseline and the 60 mg
modified dose with Simulink Pacing enabled, shows live HR / CO / MAP gauges,
and overlays the two runs in a side-by-side comparison.
```

**Expected action:** Calls `demo/realtime_dashboard.m`, which:
- Enables Simulink Pacing (`PaceRate = 5 ms/sim-sec`) so a 3600 s sim plays in ~18 s wall-clock
- Runs the 50 mg case, then the 60 mg case, back-to-back
- Live-updates three `uigauge` widgets (HR, CO, MAP) from `RuntimeObject` queries
- Accumulates both runs on overlaid time-history axes with a legend
- Reports the Δ steady-state between the two doses on the status bar

**Run manually** (works without Copilot if needed):

```matlab
cd(fullfile(repoRoot, 'demo'))
realtime_dashboard           % default pace (≈ 18 s/run)
realtime_dashboard(0.002)    % faster, ≈ 7 s/run
```

**Narrative bridge:**
*"And finally — watch it run. This is the same digital twin, but now you're seeing
the physiology evolve in real time, with both dose scenarios drawn on the same
axes. The cardiologist gets an immediate visual answer to: how does this patient
respond to the dose change?"*

---

## Timing Guide

| Prompt | Expected Duration | Cumulative |
|--------|-----------------|-----------|
| 1 | 45–60 s | ~1 min |
| 2 | 30–45 s | ~2 min |
| 3 | 20–30 s | ~2.5 min |
| 4 | 60–90 s | ~4 min |
| 5 | 30–45 s | ~5 min |
| 6 | 45–60 s | ~6 min |
| 7 | 45–60 s | ~7 min |
| 8 | 40–60 s | ~8 min |

**Total live demo: ~8 minutes** (target: under 10 minutes with narration)

---

## Optional deep dive — Prompts 9–11

The first 8 prompts are the polished live demo. Prompts 9 through 11 are an
**optional deep dive** for an engineering audience that wants to see Copilot
explain the embedded Hill nonlinearity, perform a closed-loop linearization
stability check, and run a Monte Carlo virtual-patient cohort.

Plan an extra **5 to 10 minutes** total if you run any of these, plus about
**3 to 4 minutes of wall-clock** for the cohort simulation in Prompt 11.

---

## Prompt 9 — Explain the Hill/Emax receptor binding

```
Walk me through the HeartRateModel subsystem. It has a Fcn block called
HillEquation; explain what equation that block evaluates, what each
parameter means clinically, and what the drug effect curve looks like
across the 0 to 200 mg concentration range. Then show me the marginal
effect of going from 50 to 60 mg and explain why it's smaller than what
a linear gain would predict.
```

**Expected MCP tools:** `model_read` on `HeartRateModel/HillEquation`,
`model_resolve_params` on `emax_bpm` / `ec50_mg` / `hill_n`,
`evaluate_matlab_code` for the curve plot.
**Expected output:** Copilot identifies the Hill expression
`emax_bpm*u^hill_n / (ec50_mg^hill_n + u^hill_n)`, explains
Emax = 18 bpm as the receptor-saturation ceiling, EC50 = 35 mg as the
half-maximal concentration, and Hill n = 1.5 as cooperativity. Computes
50→60 mg marginal drop of about 1.1 bpm (open loop) vs the ~2.4 bpm a
linear gain would predict, and produces a dose-response curve plot.

**Narrative bridge:**
*"In real clinical pharmacology, doubling a dose almost never doubles
the effect. Copilot just read the model, identified the Hill block, and
explained the saturation in clinical terms — without me writing a single
line of code. That's the kind of model literacy that takes a new engineer
weeks to develop."*

---

## Prompt 10 — Closed-loop linearization and stability margins

```
The model has a baroreflex feedback loop from MAP back to HR. I want
to confirm the closed loop is stable and quantify how much the loop
attenuates the dose-to-HR response. Run a linearization at the 60 mg
steady-state operating point with the baroreflex active, and again
with the baroreflex gain set to zero. Report the closed-loop poles,
the DC gain difference, and the bandwidth shift. Show a Bode plot
comparing the two.
```

**Expected MCP tools:** `evaluate_matlab_code` running
`analysis/linearize_baroreflex.m` (Simulink Control Design's
`linearize` + `findop` for the steady-state op point).
**Expected output:** Open-loop DC gain ~-0.152 bpm/mg, closed-loop
~-0.111 bpm/mg (about 27% attenuation), closed-loop adds a slow
stable pole at ~-0.023 rad/s, no instability. Bode plot showing
the closed loop rolls off earlier.

**Narrative bridge:**
*"Real cardiovascular systems aren't open loops. When the drug lowers
blood pressure, the baroreflex senses it and pushes heart rate back up.
Copilot just linearized the closed loop, confirmed it's stable, and
quantified the gain reduction — a normal control-engineering check on
what was a pharmacology problem ten seconds ago."*

---

## Prompt 11 — Virtual patient cohort with PRCC sensitivity

```
A nominal patient is a starting point, not a population. Run the
Monte Carlo cohort wrapper in analysis/run_patient_cohort.m. It
samples 100 virtual patients with log-normal PK and Hill parameters
and normal physiology parameters around the nominal values, then
runs each patient at both 50 mg and 60 mg using parsim. Then run
analysis/sensitivity_tornado.m to compute the PRCC sensitivity tornado
against HR at 60 mg and tell me which parameters dominate.
```

**Expected MCP tools:** `evaluate_matlab_code` (parsim cohort + PRCC),
`check_matlab_code` (validate scripts before running)
**Expected output:** Cohort summary shows ~9 bpm standard deviation
around the nominal HR mean. Tornado ranks Baseline HR (PRCC +0.96) as
the dominant driver, followed by SVR (−0.77) and stroke volume (−0.67).
Drug-specific parameters (Emax, EC50) rank lower because the cohort
spread in baseline physiology dominates the dose response.

**Narrative bridge:**
*"And here's the population view. The interesting story isn't the mean.
It's the spread. About a quarter of these virtual patients respond much
less than the nominal patient, and a few respond much more. The PRCC
tornado tells the clinician where their per-patient calibration matters
most: baseline heart rate and vascular resistance, not the drug dose."*

---

## Deep-dive Timing Guide

| Prompt | Expected Duration | Cumulative |
|--------|------------------:|-----------:|
| 9      | 45-75 s (model read + curve plot)           | ~1 min   |
| 10     | 60-90 s (linearize + Bode)                  | ~2.5 min |
| 11     | 90-180 s (cohort sim runs in background)    | ~5 min   |

**Total deep dive: 4 to 6 minutes** depending on cohort wall-clock.
End-to-end the cohort uses about 3 to 4 minutes of MATLAB simulation
time on a machine without Parallel Computing Toolbox; with parsim and
a 4-worker pool it drops to under 60 s.
