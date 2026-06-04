# Scripted Fallback Runbook

Use this runbook if the live Copilot session is unreliable or unavailable.  
All outputs below are **pre-verified expected responses** that can be read aloud  
or displayed as screenshots/slides.

**Trigger:** Switch to this runbook if:
- Any live prompt takes >30 seconds with no progress
- MCP tools return errors
- MATLAB session is unresponsive
- Network/Copilot connectivity issues

---

## Step 1 — Model Overview (Fallback Output)

**Slide/Read aloud:**

> *"I've analyzed the `CardiacDigitalTwin` Simulink model. It contains four  
> interconnected subsystems that model the physiological pathway from drug  
> administration to haemodynamic response:*
>
> 1. **BetaBlockerPK** — A first-order pharmacokinetic model (transfer function  
>    `1/(1800s + 1)`) that converts the administered dose in mg into a steady-state  
>    plasma concentration, with a 30-minute time constant representing absorption  
>    and elimination.
>
> 2. **HeartRateModel** — Computes heart rate as:  
>    `HR = baseline_heart_rate − beta_hr_sensitivity × plasma_concentration`  
>    Clamped to the physiological range of 40–180 bpm.
>
> 3. **CardiacOutputModel** — Computes cardiac output:  
>    `CO (L/min) = HR (bpm) × stroke_volume_mL / 1000`
>
> 4. **BloodPressureModel** — Computes mean arterial pressure:  
>    `MAP (mmHg) = CO × svr_mmHg_min_per_L`
>
> The model is driven by a single input — `beta_blocker_dose_mg` — and produces  
> three haemodynamic outputs: heart rate, cardiac output, and MAP."*

---

## Step 2 — Parameter Discovery (Fallback Output)

**Slide/Read aloud:**

> *"Using `model_query_params` and `model_resolve_params`, I located the dosage  
> parameter:*
>
> | Parameter | Value | Units | Location |
> |-----------|-------|-------|---------|
> | `beta_blocker_dose_mg` | **50** | mg | `BetaBlockerDose` constant block (top level) |
> | `beta_hr_sensitivity` | 0.24 | bpm/mg | `HeartRateModel/BetaSensitivity` gain block |
> | `pk_time_constant` | 1800 | seconds | `BetaBlockerPK/PKTransferFcn` denominator |
>
> *At the current dose of 50 mg, the model predicts a steady-state HR reduction of  
> 12 bpm, resulting in a resting heart rate of ~63 bpm — consistent with published  
> clinical data for metoprolol succinate 50 mg/day."*

---

## Step 3 — Parameter Edit (Fallback Output)

**Slide/Read aloud:**

> *"I've updated `beta_blocker_dose_mg` from 50 mg to 60 mg (+20%) using  
> `model_edit`. The change was applied to the `BetaBlockerDose` constant block.  
> The updated value has been verified:*
>
> ```
> Before: beta_blocker_dose_mg = 50 mg
> After:  beta_blocker_dose_mg = 60 mg   ← ✅ confirmed
> ```
>
> *The model is ready to simulate the new dosing scenario."*

---

## Step 4 — Simulation Results (Fallback Output)

**Slide/Read aloud (display comparison table):**

> *"I ran both simulations to steady state (1-hour simulation window, ode45 solver).  
> Here are the steady-state haemodynamic results:*

| Metric | Baseline (50 mg) | Modified (60 mg) | Change |
|--------|:----------------:|:----------------:|:------:|
| Heart Rate | 63.0 bpm | 60.6 bpm | **−2.4 bpm (−3.8%)** |
| Cardiac Output | 4.41 L/min | 4.24 L/min | **−0.17 L/min (−3.9%)** |
| Mean Art. Pressure | 79.4 mmHg | 76.3 mmHg | **−3.1 mmHg (−3.9%)** |

> *All three metrics decreased as expected, confirming the model correctly  
> captures the negative chronotropic and mild antihypertensive effects of  
> increased beta-blocker dosage."*

---

## Step 5 — Clinical Interpretation (Fallback Output)

**Slide/Read aloud:**

> *"Clinical assessment of the simulated dose change:*
>
> ✅ **Heart rate (60.6 bpm):** Within the target range for rate control (55–65 bpm).  
> Not approaching bradycardia threshold (<50 bpm). Appropriate for a hypertensive  
> patient on beta-blocker therapy.
>
> ✅ **Cardiac output (4.24 L/min):** Adequate. Clinical concern threshold is  
> approximately 3.0 L/min. The reduction is haemodynamically acceptable.
>
> ✅ **MAP (76.3 mmHg):** Moved toward the hypertension treatment target  
> (<80 mmHg). Modest but clinically meaningful contribution.
>
> ⚠️ **Flag for cardiologist:** The 3.8% HR reduction is at the lower end of  
> expected response. If the patient is symptomatic (fatigue, dizziness), consider  
> titrating more gradually. Recommend re-evaluation at the next clinical visit."*

---

## Step 6 — Validation Test (Fallback Output)

**Slide/Read aloud:**

```gherkin
Feature: Beta-blocker dose-response validation
  # Verifies the cardiac model correctly responds to metoprolol titration

  Scenario: Increased metoprolol dose reduces heart rate
    Given the CardiacDigitalTwin model is initialized
    And beta_blocker_dose_mg is set to 50
    And the simulation has reached steady state
    When beta_blocker_dose_mg is increased to 60
    And the simulation is re-run to steady state
    Then steady-state heart rate should decrease by at least 2 bpm
    And steady-state heart rate should remain above 40 bpm
    And cardiac output should decrease by at least 0.1 L/min
    And cardiac output should remain above 3.0 L/min

  Scenario: No medication produces baseline physiology
    Given the CardiacDigitalTwin model is initialized
    And beta_blocker_dose_mg is set to 0
    And the simulation has reached steady state
    Then steady-state heart rate should equal 75 bpm (±1 bpm)
```

> *"Both scenarios pass. The model demonstrates correct dose-response behavior,  
> providing traceable, automated evidence for the design verification record."*

---

## Branch Logic

| Situation | Action |
|-----------|--------|
| Step 1 fails (model not described) | Show architecture diagram slide; continue from Step 2 |
| Step 2 fails (params not found) | Read parameter table from Step 2 verbatim |
| Step 3 fails (edit not applied) | Show "before/after" parameter comparison slide |
| Step 4 fails (simulation error) | Show pre-computed results table; continue to Step 5 |
| Steps 1–4 all fail | Jump directly to Step 5 + Step 6 (interpretation + test) |
| Entire session fails | Walk through the architecture diagram; narrate the clinical story |
