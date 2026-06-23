# Validation

The validation story has two halves.

1. **The Gherkin-driven verification test** that proves the model satisfies its dose-response requirement, runnable in about 3 seconds from a single MCP call.
2. **The MATLAB validation suite** that exercises the full simulation pipeline against analytical expectations.

Both are persistent, reusable, and trace back to the engineering requirements in [Requirements](requirements.md).

---

## The Gherkin test

File: [`validation/beta_blocker_dose_response.feature`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/beta_blocker_dose_response.feature).

Test target: the `HeartRateModel` subsystem. Because the PK stage has unity DC gain, feeding a constant concentration is equivalent to a full-pipeline run at that dose at steady state.

### The file

```gherkin
# --- front-matter:toml ---
model = "CardiacDigitalTwin.slx"
component = "CardiacDigitalTwin/HeartRateModel"
[inputs]
Concentration = "ConcentrationIn"
BaroreflexIn  = "BaroreflexIn"
[outputs]
HR = "HeartRateOut"
# --- end front-matter ---

Feature: Beta-blocker dose-response on heart rate
  Verifies the Hill/Emax HeartRateModel in open-loop (baroreflex held
  at zero) for two dose levels. At PK steady state, plasma concentration
  equals dose (PK gain = 1), so a constant concentration input is the
  equivalent dose at steady state. Driving BaroreflexIn = const(0)
  isolates the Hill block and clamp from the closed feedback loop.

Scenario: Baseline 50 mg dose with no baroreflex correction
  Given inputs
    * Concentration = const(50)
    * BaroreflexIn  = const(0)
  When simulate for 1s in Normal mode
  Then outputs
    * BaselineUpperBound: HR <= 63.9
    * BaselineLowerBound: HR >= 63.4

Scenario: Increased 60 mg dose still drops HR despite Hill saturation
  Given inputs
    * Concentration = const(60)
    * BaroreflexIn  = const(0)
  When simulate for 1s in Normal mode
  Then outputs
    * IncreasedDoseUpperBound: HR <= 62.8
    * IncreasedDoseLowerBound: HR >= 62.3
    * NotBelowClamp: HR >= 40
```

### How the at-least-0.5-bpm requirement is enforced

Gherkin scenarios are independent. They cannot reference each other's values. The requirement is enforced *across* the two scenarios using bounded windows. The bounds are the **open-loop** Hill response (`BaroreflexIn = const(0)`), which isolates the drug effect from the feedback loop.

| Scenario | Asserted window | Analytical value |
|---|:---:|:---:|
| 50 mg | \([63.4,\ 63.9]\) bpm | 63.65 bpm |
| 60 mg | \([62.3,\ 62.8]\) bpm | 62.55 bpm |
| **Minimum guaranteed drop** | \(63.4 - 62.8 = 0.6\) bpm | meets the requirement (at least 0.5 bpm) |

If both scenarios pass, the model exhibits at least a 0.6 bpm open-loop reduction. The drop is small *by design*: the Hill curve is already past its EC50 at 50 mg, so each extra milligram does less. The bounds are tight enough that a calibration drift is caught, but loose enough to tolerate normal solver settling.

### Running it

From a Copilot prompt:

```
Run the dose-response Gherkin test on the cardiac model.
```

That invokes the `model_test` MCP tool, which does the following.

1. Reads the `.feature` file.
2. Generates a Simulink Test harness for `HeartRateModel`.
3. Runs the scenarios in draft mode (no main-model compile).
4. Returns pytest-style results.

Expected output:

```
================== test session starts ==================
  model: CardiacDigitalTwin.slx
  gherkin: validation/beta_blocker_dose_response.feature
  scenarios: 2

  Summary: 2 passed in 3.01s
    Assessments: 5 passed, 0 failed, 0 untested of 5

  PASSED scenario: Baseline 50 mg dose with no baroreflex correction (1.73s)
  PASSED scenario: Increased 60 mg dose still drops HR despite Hill saturation (1.28s)

================== Execution time: 3.01s ================
```

### Why subsystem-level testing

`model_test` needs a component with `Inport` and `Outport` ports. The model root uses a `Constant` block bound to a workspace variable, so it has no input port to drive. The `HeartRateModel` subsystem, on the other hand, has clean signal-based I/O, which is what the harness creation expects.

Trading "full pipeline" for "subsystem" is sound here because the PK stage is deterministically equivalent to identity at steady state. The test is *less* ambiguous as a result, not more.

### Why draft mode

`draft_mode=true` skips the main-model compile and uses a lightweight harness. For a memoryless subsystem like `HeartRateModel` (Fcn for the Hill term, Sum, Saturation), this cuts execution from about 60 s to about 3 s with no loss of correctness. Re-running in `draft_mode=false` against the compiled model gives the same results.

---

## The MATLAB validation suite

File: [`validation/validate_beta_blocker.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/validate_beta_blocker.m).

This is the longer-form sister to the Gherkin test. It runs the **full** pipeline at both doses, computes steady-state means over the final 10 % of the simulation window, and checks each output against the analytical prediction.

```matlab
% Pseudocode of the assertion structure (full closed-loop pipeline)
baseline_dose = 50;   modified_dose = 60;

% Closed-loop steady-state targets (final 10 % of the run)
expected_HR_50 = 67.4;   % closed-loop, with baroreflex
expected_HR_60 = 66.6;

assert(abs(measured_HR_50 - expected_HR_50) < 0.5)
assert(abs(measured_HR_60 - expected_HR_60) < 0.5)
assert((measured_HR_50 - measured_HR_60) >= 0.5)   % directional dose-response
```

The acceptance criteria are documented in [`validation/validation_criteria.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/validation_criteria.md): 10 pass/fail criteria covering analytical agreement, dose-response direction, clinical safety bands, and the saturation clamp.

### When to use which

| Use Gherkin (`model_test`) when… | Use MATLAB validation (`validate_beta_blocker.m`) when… |
|---|---|
| Verifying a single subsystem's behaviour. | Verifying the full pipeline end-to-end. |
| Driving the assertion from a requirement statement. | Doing exploratory data analysis on simulation output. |
| Catching regressions in CI quickly (about 3 s). | Producing a detailed validation report. |
| The test target has clean Inport and Outport signals. | The test target reads from `To Workspace` blocks at root. |

In practice both run as part of pre-commit validation: the Gherkin test as a fast gate, the MATLAB suite as a thorough check before publishing.

---

## How this fits the requirements

```mermaid
flowchart LR
    REQ001[REQ_CDT_001<br/>System: ≥0.5 bpm drop at 50→60 mg] -->|verified by| GH[Gherkin test]
    REQ002[REQ_CDT_002<br/>Perf: Hill/Emax HR form ±0.5 bpm] -->|verified by| GH
    REQ002 -->|verified by| ML[MATLAB suite]
    REQ003[REQ_CDT_003<br/>Safety: CO ≥ 4.0 L/min @ dose ≤ 100 mg] -->|verified by| ML

    GH -->|model element| HR[HeartRateModel<br/>blk_3]
    ML -->|model element| Root[CardiacDigitalTwin]
```

REQ_CDT_003 holds across the therapeutic range: the Hill curve saturates near `emax_bpm`, so at 100 mg the open-loop CO is about 4.21 L/min (closed-loop ~4.6), staying above the 4.0 L/min floor. The receptor-saturation physics supplies the safety margin rather than an arbitrary guard — exactly the kind of property the cardiologist review process is meant to confirm before baselining.

---

## What "validated" means here

Validation in this demo means three things hold simultaneously.

1. **The model agrees with its analytical specification.** At every dose across the therapeutic range, the simulation output matches the closed-form Hill/baroreflex fixed point within tolerance.
2. **The model agrees with itself across dose changes.** The dose-response delta is monotonic, proportional, and matches the predicted percent change.
3. **The model agrees with clinical reference values.** At standard doses the outputs land inside published physiological ranges.

The Gherkin test covers (1) and (2) in the chronotropic path. The MATLAB suite covers all three end-to-end. Together they let the requirement set in [Requirements](requirements.md) carry confidence: every requirement has a verification artifact behind it.
