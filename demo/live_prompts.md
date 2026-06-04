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

**Total live demo: ~7 minutes** (target: under 9 minutes with narration)
