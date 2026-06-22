# Advanced physiology (Phase 2)

The base [Model architecture](architecture.md) page describes the v1 model: four linear subsystems wired in a feed-forward chain, no feedback, one nominal patient. That model is small on purpose. It is the right shape for a 7-prompt live demo because every block can be read at a glance and every parameter has an obvious clinical meaning.

But a real pharmacological digital twin is not feed-forward and not linear. Drugs bind to receptors with saturable kinetics, the autonomic nervous system closes a feedback loop around blood pressure, and no two patients respond the same way. This page describes the Phase 2 extensions that close those three gaps, the new files in the repo, and the Copilot prompts that drove them.

The Phase 2 work lives alongside the v1 model rather than replacing it. The 7-prompt demo still runs against [`CardiacDigitalTwin.slx`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/CardiacDigitalTwin.slx); the deep-dive prompts 9 through 11 run against [`CardiacDigitalTwin_v2.slx`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/CardiacDigitalTwin_v2.slx).

---

## What changes from v1 to v2

| Aspect | v1 (base demo) | v2 (Phase 2 advanced) |
|---|---|---|
| Drug effect on HR | Linear gain: `effect = beta_hr_sensitivity * concentration` | Hill/Emax: `effect = Emax * C^n / (EC50^n + C^n)` |
| Cardiovascular loop | Open (feed-forward) | Closed via `BaroreflexController` (MAP feeds back into HR) |
| Patients simulated | One nominal patient per run | Monte Carlo cohort of 100 patients per dose, sampled from population distributions |
| Analysis surface | Steady-state table, time-history plots | Cohort summary, PRCC tornado plot, closed-loop linearization, Bode plot |
| Simulink toolboxes used | Simulink only | Simulink + Simulink Control Design + Parallel Computing Toolbox |

The v2 model file is [`model/CardiacDigitalTwin_v2.slx`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/CardiacDigitalTwin_v2.slx). It is built programmatically by [`model/create_cardiac_model_v2.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/create_cardiac_model_v2.m) and uses parameters from [`model/cardiac_params_v2.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/cardiac_params_v2.m).

---

## Prompt 9. Nonlinear receptor binding (Hill/Emax)

### Why this matters clinically

In v1 the drug effect is linear in plasma concentration: doubling the dose doubles the heart-rate drop. That is fine at low doses, but real receptor binding saturates. Once you have blocked most of the beta-1 receptors on the cardiac pacemaker cells, adding more drug stops adding effect. The clinically relevant phrase is *diminishing returns at higher doses*, and getting it wrong leads to overdosing without therapeutic benefit.

The standard pharmacological model for this is the Hill equation:

\[
\text{DrugEffect}(C) \;=\; E_{\max} \cdot \frac{C^n}{EC_{50}^n + C^n}
\]

with three parameters:

| Parameter | Meaning | v2 value |
|---|---|---:|
| \(E_{\max}\) | Maximum effect the drug can ever produce | 18 bpm |
| \(EC_{50}\) | Concentration that gives half-maximal effect | 35 mg |
| \(n\) | Hill coefficient (cooperativity) | 1.5 |

At low \(C\), the response is roughly linear in \(C^n / EC_{50}^n\). At \(C = EC_{50}\), the response is exactly \(E_{\max}/2\). As \(C \gg EC_{50}\), the response approaches \(E_{\max}\) and flattens.

### What v2 actually does at 50 vs 60 mg

| Quantity | v1 (linear) | v2 (Hill + baroreflex) |
|---|---:|---:|
| HR at 50 mg | 63.0 bpm | 67.4 bpm |
| HR at 60 mg | 60.6 bpm | 66.6 bpm |
| Marginal HR drop | −2.4 bpm | −0.9 bpm |
| Marginal as % | −3.8 % | −1.3 % |

The marginal drop is **less than half** in v2. This is exactly the saturation effect a clinician would want to see when deciding whether to push a dose higher.

### What Copilot does in this prompt

Copilot edits the `HeartRateModel` subsystem to replace the `BetaSensitivity` Gain block with a `Fcn` block evaluating the Hill expression, then regenerates the validation test and updates `REQ_CDT_002` to reference the new formula. The relevant MCP tools are `model_read`, `model_edit`, and `model_test`.

---

## Prompt 10. Baroreflex feedback loop

### Why this matters clinically

The cardiovascular system is a closed loop in real bodies. When MAP drops, baroreceptors in the carotid sinus and aortic arch fire less, the brainstem withdraws parasympathetic tone and adds sympathetic tone, and HR rises. That is the *baroreflex*, and it is the reason real patients on a beta-blocker do not collapse the moment the drug starts working.

The v1 open-loop model ignores this. v2 adds a `BaroreflexController` subsystem:

\[
\text{HR}_\text{correction}(s) \;=\; \frac{K_\text{baro}}{\tau_\text{baro}\, s + 1}\, (\text{MAP}_\text{setpoint} - \text{MAP})
\]

with \(K_\text{baro} = 0.30\) bpm/mmHg, \(\tau_\text{baro} = 60\) s, setpoint 94 mmHg. The correction is added back into `HeartRateModel` as a second input.

### Stability and the linearization

The closed loop must be stable. Copilot runs [`analysis/linearize_baroreflex.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/analysis/linearize_baroreflex.m), which uses Simulink Control Design's `linearize` at a steady-state operating point (snapshotted at \(t = 3600\) s so the Hill expression evaluates at a meaningful concentration) for both the open and closed loops:

| Metric | Open loop | Closed loop |
|---|---:|---:|
| DC gain (bpm per mg of dose) | −0.152 | −0.111 |
| Poles | −0.0006 | −0.0230, −0.0006 |
| Stable | yes | yes |

Two takeaways:

1. The baroreflex reduces the dose-to-HR DC gain by about 27%. The drug becomes effectively weaker because the autonomic system fights back.
2. The closed loop adds a fast stable pole at −0.023 rad/s without destabilising the slow PK pole. No stability margin is at risk.

The script also produces a Bode plot comparing open and closed loops; the closed-loop magnitude rolls off earlier, which matches the slower HR response observed in the time-domain simulations.

### What Copilot does in this prompt

Copilot adds the `BaroreflexController` subsystem, routes MAP back to a second inport on `HeartRateModel`, and runs `linearize_baroreflex.m`. The relevant MCP tools are `model_edit` (multiple subsystem and wiring operations) and `evaluate_matlab_code` for the linearization workflow.

---

## Prompt 11. Virtual patient cohort

### Why this matters clinically

A nominal patient is a useful starting point but a poor representation of a clinical population. Two patients with the same dose and the same baseline HR can land 15 bpm apart at steady state because their PK clearance, receptor density, baseline SVR, and stroke volume are all different. Monte Carlo over these parameters gives a population-level view of dose response, the kind of analysis a phase-2 trial would expect.

[`analysis/run_patient_cohort.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/analysis/run_patient_cohort.m) samples 100 virtual patients per dose:

| Parameter | Distribution | CV / sigma |
|---|---|---|
| `pk_time_constant`     | log-normal around nominal | sigma 0.25 |
| `emax_bpm`             | log-normal around nominal | sigma 0.25 |
| `ec50_mg`              | log-normal around nominal | sigma 0.25 |
| `hill_n`               | normal, floored at 0.5     | CV 0.15 |
| `baseline_heart_rate`  | normal, floored at 50      | CV 0.15 |
| `stroke_volume_mL`     | normal                     | CV 0.15 |
| `svr_mmHg_min_per_L`   | normal                     | CV 0.15 |

The script builds a `Simulink.SimulationInput` per patient per dose (200 runs), uses `parsim` when Parallel Computing Toolbox is available and falls back to `arrayfun(@sim, ...)` otherwise.

### Cohort summary at 50 vs 60 mg

| Dose | HR (bpm, mean ± sd) | CO (L/min, mean ± sd) | MAP (mmHg, mean ± sd) |
|---|---|---|---|
| 50 mg | 67.5 ± 9.1 | 4.80 ± 0.72 | 85.3 ± 18.6 |
| 60 mg | 66.7 ± 9.1 | 4.74 ± 0.72 | 84.3 ± 18.5 |

The mean dose effect is small (about 1 bpm) but the standard deviation is large (about 9 bpm). For roughly 25 of the 100 simulated patients, the dose increase moves HR by *less* than the nominal effect; for others it moves it by twice as much. That spread is the clinically interesting story.

### Sensitivity tornado (PRCC)

[`analysis/sensitivity_tornado.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/analysis/sensitivity_tornado.m) computes the partial rank correlation coefficient (PRCC) between each sampled parameter and the cohort HR response at 60 mg. PRCC is the standard global sensitivity metric for Monte Carlo population pharmacology because it is rank-based (robust to nonlinearity) and partials out the other inputs.

| Parameter | PRCC vs HR at 60 mg |
|---|---:|
| Baseline HR     | +0.96 |
| SVR             | −0.77 |
| Stroke volume   | −0.67 |
| Emax            | −0.62 |
| EC50            | +0.29 |
| PK time constant| +0.19 |
| Hill n          | −0.11 |

Two readings:

1. **Baseline HR dominates.** The single biggest driver of where a patient ends up is where they started. Drug pharmacology comes second.
2. **Negative SVR correlation.** Patients with higher peripheral resistance have lower HR at steady state, because the baroreflex senses the higher MAP and pulls HR down. The closed loop in v2 makes this visible; v1 would have shown a near-zero correlation here.

The tornado plot orders these by `|PRCC|` and colours positive vs negative correlations.

### What Copilot does in this prompt

Copilot generates the `parsim` cohort wrapper and the PRCC tornado script, then runs both. The relevant MCP tools are `evaluate_matlab_code` to execute the cohort and `check_matlab_code` to validate the generated scripts before running.

---

## What this proves about the toolchain

Phase 2 took the v1 model from a four-block linear demo to a closed-loop nonlinear population-pharmacology workbench without changing the simulation engine or rewriting any v1 code. Each step was a Copilot prompt that used the MCP tools as primitives:

| Capability | MCP surface |
|---|---|
| Structural refactor (gain to nonlinear Fcn) | `model_read`, `model_edit` |
| Add a new subsystem and close a feedback loop | `model_edit` |
| Linearize at a custom operating point | `evaluate_matlab_code` (Simulink Control Design) |
| Build and run a Monte Carlo cohort | `evaluate_matlab_code` (parsim) |
| Validate generated scripts before running | `check_matlab_code` |

The same prompt-driven workflow that scaled to the four-equation v1 model scales to a closed-loop nonlinear cohort. That is the point worth making at the end of the demo.

---

## Running it yourself

```matlab
% Build the v2 model (one-time)
run('model/cardiac_params_v2.m');
run('model/create_cardiac_model_v2.m');

% Single-patient nominal comparison (Phase 2 quick smoke test)
run('model/run_simulation_v2.m');

% Closed-loop linearization (Prompt 10)
run('analysis/linearize_baroreflex.m');

% Monte Carlo cohort + sensitivity (Prompt 11)
run('analysis/run_patient_cohort.m');
run('analysis/sensitivity_tornado.m');
```

Total wall-clock for a fresh run on a workstation without Parallel Computing Toolbox is about 3 to 4 minutes, dominated by the 200 cohort simulations.
