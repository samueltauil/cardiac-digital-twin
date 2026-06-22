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
the DrugPK transfer function, which produces plasma concentration, which reduces HR  
via `beta_hr_sensitivity = 0.24 bpm/mg`.

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
| Heart Rate | ~63 bpm | ~60.6 bpm | −3.8% |
| Cardiac Output | ~4.41 L/min | ~4.24 L/min | −3.9% |
| Mean Art. Pressure | ~79.4 mmHg | ~76.3 mmHg | −3.9% |

**Narrative bridge:**  
*"The simulation ran. We can see the model-predicted physiological response  
to the dose change — all three haemodynamic metrics moved in the expected  
direction, confirming the therapeutic intent."*

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
- HR reduction of ~2.4 bpm is modest but directionally correct for rate control
- MAP reduction of ~3 mmHg contributes to antihypertensive goal
- HR at ~61 bpm is within safe range (not approaching bradycardia threshold of <50 bpm)
- Cardiac output remains adequate (~4.24 L/min > clinical concern threshold of ~3 L/min)
- Flag: monitor for symptomatic bradycardia; re-evaluate at next clinical visit

**Narrative bridge:**  
*"This is where it gets powerful. Copilot doesn't just run the simulation —  
it interprets the results in clinical context. It gives the cardiologist  
an immediate, evidence-based summary ready for the patient record."*

---

## Prompt 6 — Generate a Validation Test

```
Write a Gherkin-style test scenario that verifies the cardiac model
correctly shows a reduction in heart rate when beta-blocker dose is
increased from 50 mg to 60 mg. The test should check that
steady-state heart rate decreases by at least 2 bpm.
```

**Expected MCP tools:** `model_test` (Gherkin test generation)  
**Expected response:** A Gherkin scenario such as:

```gherkin
Feature: Beta-blocker dose-response validation

  Scenario: Increased metoprolol dose reduces heart rate
    Given the cardiac model is initialized with beta_blocker_dose_mg = 50
    And the simulation reaches steady state
    When beta_blocker_dose_mg is increased to 60
    And the simulation is re-run to steady state
    Then the steady-state heart rate should decrease by at least 2 bpm
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

## Phase 2 — Optional deep dive (Prompts 9–11)

The first 8 prompts are the polished live demo. Prompts 9 through 11 are an
**optional deep dive** for an engineering audience that wants to see Copilot
handle structural refactors, feedback-loop wiring, and Monte Carlo workflows.
They use a second model, `CardiacDigitalTwin_v2.slx`, kept alongside v1 so the
linear demo stays intact.

Plan an extra **5 to 10 minutes** total if you run any of these, plus about
**3 to 4 minutes of wall-clock** for the cohort simulation in Prompt 11.

---

## Prompt 9 — Nonlinear receptor binding (Hill/Emax)

```
The v1 HeartRateModel uses a linear gain (beta_hr_sensitivity) to relate
plasma concentration to heart-rate drop. That's not how real receptor
binding works — it saturates. Build a v2 model called CardiacDigitalTwin_v2
that replaces the linear gain with a Hill/Emax expression:

  DrugEffect(C) = emax_bpm * C^hill_n / (ec50_mg^hill_n + C^hill_n)

with emax_bpm=18, ec50_mg=35, hill_n=1.5. Save the new model and run a
50 mg vs 60 mg comparison. Show me how the marginal HR drop changes.
```

**Expected MCP tools:** `model_read`, `model_edit`, `evaluate_matlab_code`
**Expected output:** A new `model/CardiacDigitalTwin_v2.slx`, a v2 params file,
and a comparison showing the marginal HR drop at +20% dose shrinks from
about −2.4 bpm (v1 linear) to about −0.9 bpm (v2 Hill saturation).

**Narrative bridge:**
*"In real clinical pharmacology, doubling a dose almost never doubles the
effect. Copilot just replaced a single Gain block with a Hill equation and
the model immediately shows the saturation. That's the clinical reasoning
the cardiologist needs to set the right dose."*

---

## Prompt 10 — Close the cardiovascular loop with a baroreflex

```
Now close the cardiovascular loop. Add a BaroreflexController subsystem
to CardiacDigitalTwin_v2 that takes MAP as input and outputs an HR
correction equal to baroreflex_gain * (map_setpoint_mmHg - MAP), filtered
through a first-order lag with time constant baroreflex_tau. Route that
correction back as a second input to HeartRateModel.

Then linearize the closed loop around steady state and confirm it's
stable. Report the closed-loop poles and the change in DC gain compared
to the open-loop case.
```

**Expected MCP tools:** `model_edit` (multiple subsystem + wiring ops),
`evaluate_matlab_code` (linearize + analysis), `check_matlab_code`
**Expected output:** New `BaroreflexController` subsystem, closed feedback
loop wired in, `analysis/linearize_baroreflex.m` run. Reports DC gain
drops from −0.152 to −0.111 bpm/mg (about 27% reduction) and adds a
slow stable pole at −0.023 rad/s. Closed loop is stable.

**Narrative bridge:**
*"Real cardiovascular systems aren't open loops. When the drug lowers
blood pressure, the baroreflex senses it and pushes heart rate back up.
Copilot just closed that loop and verified the closed system is still
stable using linearization — that's a normal control-engineering check
on what was a pharmacology problem ten seconds ago."*

---

## Prompt 11 — Virtual patient cohort with PRCC sensitivity

```
A nominal patient is a starting point, not a population. Write a Monte
Carlo cohort wrapper that samples 100 virtual patients with log-normal
PK and Hill parameters and normal physiology parameters around the
nominal values. Run each patient at both 50 mg and 60 mg using parsim
(or sim if Parallel Computing Toolbox isn't available). Then compute a
PRCC sensitivity tornado against HR at 60 mg and tell me which
parameters dominate the response.
```

**Expected MCP tools:** `evaluate_matlab_code` (parsim cohort + PRCC),
`check_matlab_code` (validate generated scripts)
**Expected output:** `analysis/run_patient_cohort.m` and
`analysis/sensitivity_tornado.m` run. Cohort summary shows ~9 bpm
standard deviation around the nominal HR mean. Tornado ranks Baseline HR
(PRCC +0.96) as the dominant driver, followed by SVR (−0.77) and stroke
volume (−0.67). Drug-specific parameters (Emax, EC50) rank lower because
the cohort spread in baseline physiology dominates the dose response.

**Narrative bridge:**
*"And here's the population view. The interesting story isn't the mean —
it's the spread. About a quarter of these virtual patients respond much
less than the nominal patient, and a few respond much more. The PRCC
tornado tells the clinician where their per-patient calibration matters
most: baseline heart rate and vascular resistance, not the drug dose."*

---

## Phase 2 Timing Guide

| Prompt | Expected Duration | Cumulative |
|--------|------------------:|-----------:|
| 9      | 60–90 s (model refactor) | ~1.5 min |
| 10     | 90–120 s (subsystem + linearization) | ~3.5 min |
| 11     | 90–180 s (cohort sim runs in background) | ~5–6 min |

**Total Phase 2 deep dive: 5 to 10 minutes** depending on cohort wall-clock.
Phase 2 is end-to-end about 3 to 4 minutes of MATLAB simulation time on a
machine without Parallel Computing Toolbox; with parsim and a 4-worker pool
it drops to under 60 s.
