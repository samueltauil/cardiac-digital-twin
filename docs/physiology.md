# Physiology and math

Every formula in the model is here. So is the reason it was chosen, the clinical reference behind each calibrated parameter, and the closed-form steady-state derivation.

---

## Variables and parameters

| Symbol | Variable in code | Value | Units | Role |
|---|---|---:|---|---|
| \(D\) | `beta_blocker_dose_mg` | 50 (default) | mg | Daily oral metoprolol dose |
| \(\tau\) | `pk_time_constant` | 1800 | s | PK first-order time constant |
| \(\text{HR}_0\) | `baseline_heart_rate` | 75 | bpm | Drug-free resting HR |
| \(k_\beta\) | `beta_hr_sensitivity` | 0.24 | bpm/mg | Chronotropic gain per mg dose |
| \(\text{SV}\) | `stroke_volume_mL` | 70 | mL/beat | Resting stroke volume (constant) |
| \(\text{SVR}\) | `svr_mmHg_min_per_L` | 18 | mmHg·min/L | Systemic vascular resistance |

Workspace parameters live in [`model/cardiac_params.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/cardiac_params.m) and are loaded by `setup/startup.m`.

---

## The four equations

### 1. Pharmacokinetics. First-order absorption and elimination

\[
\boxed{\;C(s) \;=\; \frac{1}{\tau s + 1}\,D(s)\;}
\]

Implemented as a single `Transfer Fcn` block with numerator `[1]` and denominator `[pk_time_constant 1]`.

In the time domain, with a step input \(D(t) = D\) for \(t \geq 0\):

\[
C(t) \;=\; D\!\left(1 - e^{-t/\tau}\right)
\]

A few properties matter for the demo.

The DC gain is one: \(\lim_{t \to \infty} C(t) = D\). At steady state the plasma concentration *equals* the dose value. This is what lets the Gherkin test drive `HeartRateModel` directly with `const(50)` and `const(60)` and still represent the full-model 50 mg to 60 mg comparison.

The settling time is about 5\(\tau\) (9000 s). The simulation `StopTime` of 3600 s catches roughly 86 % of the asymptote (2 time constants); the full-validation runs extend to 9000 s.

The half-life is \(\tau \ln 2\), about 1247 s or 20.8 minutes. Metoprolol's *clinical* half-life is 3 to 7 hours; the demo uses 30 minutes to keep simulation time short while preserving the exponential *shape* of the response.

!!! note "On the unit treatment"
    The PK block has unity gain and no explicit unit conversion. We interpret
    *plasma concentration* in this model as a normalised quantity that takes the
    same numerical value as the dose. A real PK model would divide by volume of
    distribution and account for absorption, distribution, and elimination
    rates separately, but those refinements would not change the *shape* of
    the dose-response surface this demo demonstrates.

### 2. Chronotropic response. Linear gain with safety clamp

\[
\boxed{\;\text{HR}(t) \;=\; \mathrm{clamp}\!\bigl(\text{HR}_0 - k_\beta \cdot C(t),\ \ 40,\ 180\bigr)\;}
\]

At steady state this collapses to:

\[
\text{HR}_{ss} \;=\; \text{HR}_0 - k_\beta \cdot D
\;=\; 75 - 0.24 \cdot D \quad\text{[bpm]}
\]

Calibration values:

| Dose | Predicted HR | Reference HR (clinical) |
|---:|:---:|:---:|
| 25 mg | 69.0 bpm | 67 to 70 |
| 50 mg | 63.0 bpm | 60 to 65 |
| 100 mg | 51.0 bpm | 50 to 55 |

The 0.24 bpm/mg gain was chosen so that the standard 50 mg/day metoprolol succinate dose produces about a 12 bpm reduction, consistent with clinical practice.

The linear model fails outside the therapeutic range, which is why the saturation block is there. The clamp is a defensive guard that does not activate in normal use.

- Lower bound `40`: physiological floor for resting HR in a non-pacemaker patient.
- Upper bound `180`: tachycardia ceiling. Would only matter if the dose were negative.

The clamp activates at \(D = (75-40)/0.24 = 145.8\) mg, well beyond the therapeutic range. This sets the *validity domain* of the linear approximation, which the performance requirement (REQ_CDT_002) explicitly bounds to \([0, 145]\) mg.

### 3. Cardiac output. Fick-like decomposition

\[
\boxed{\;\text{CO}\ [\text{L/min}] \;=\; \text{HR}\ [\text{bpm}] \cdot \frac{\text{SV}\ [\text{mL}]}{1000}\;}
\]

A textbook decomposition: cardiac output equals beats per minute times volume per beat. The `× 1/1000` is a unit conversion from mL to L.

At baseline (\(\text{HR}_0\) with no drug, \(\text{SV} = 70\)):

\[
\text{CO}_0 \;=\; 75 \cdot \frac{70}{1000} \;=\; 5.25\ \text{L/min}
\]

a textbook adult resting cardiac output.

Beta-blockers' impact on stroke volume is small (and mixed in direction; they can slightly *increase* SV by lengthening diastolic filling time, while slightly *decreasing* contractility). At the linearity of analysis this demo aims for, treating SV as a fixed parameter gives an honest first-order picture.

### 4. Mean arterial pressure. Afterload identity

\[
\boxed{\;\text{MAP}\ [\text{mmHg}] \;=\; \text{CO}\ [\text{L/min}] \cdot \text{SVR}\ [\text{mmHg}\cdot\text{min/L}]\;}
\]

The familiar haemodynamic identity, with SVR held constant. Beta-blockers have minimal direct vasoactive effect; their MAP reduction goes through CO.

At baseline:

\[
\text{MAP}_0 \;=\; 5.25 \cdot 18 \;=\; 94.5\ \text{mmHg}
\]

which falls inside the normal adult resting range (70 to 105 mmHg).

---

## Closed-form steady-state dose response

Combining all four equations at steady state:

\[
\begin{aligned}
\text{HR}_{ss}(D) &= 75 - 0.24\,D \\
\text{CO}_{ss}(D) &= \frac{(75 - 0.24\,D) \cdot 70}{1000} \\
\text{MAP}_{ss}(D) &= \frac{(75 - 0.24\,D) \cdot 70 \cdot 18}{1000}
\end{aligned}
\]

Numerically, for the demo's two doses:

| Dose | \(\text{HR}_{ss}\) | \(\text{CO}_{ss}\) | \(\text{MAP}_{ss}\) |
|---:|:---:|:---:|:---:|
| 50 mg | 63.0 bpm | 4.41 L/min | 79.4 mmHg |
| 60 mg | 60.6 bpm | 4.24 L/min | 76.3 mmHg |

The proportional change is identical across all three outputs:

\[
\frac{\Delta\text{HR}}{\text{HR}_{50}}
\;=\; \frac{\Delta\text{CO}}{\text{CO}_{50}}
\;=\; \frac{\Delta\text{MAP}}{\text{MAP}_{50}}
\;=\; -\frac{0.24 \cdot 10}{63.0}
\;\approx\; -3.81\,\%
\]

This is a direct consequence of the linear coupling between stages (`CO = HR × const`, `MAP = CO × const`). Any percent change in HR propagates identically through both downstream stages. It is the kind of property that is instantly visible from the formulas but easy to miss in a simulation table.

---

## Why the analytics matter

Every result in this demo has a **closed-form prediction** that can be checked against the simulation.

- The Gherkin test bounds are derived from \(\text{HR}_{ss} = 75 - 0.24 \cdot D\).
- The expected-output banner in `cardiac_params.m` is generated from the same formula and printed at startup.
- The validation suite (`validation/validate_beta_blocker.m`) cross-checks simulation outputs against the analytical expectations.

This is the discipline that makes the model a *reference implementation* rather than a black box. Every output is auditable.

---

## What the demo deliberately leaves out

Honest scoping matters. This model omits:

- **Receptor-binding nonlinearity.** \(k_\beta\) is constant; a real Hill or Emax curve would flatten at high dose.
- **Baroreflex feedback.** Falling MAP would normally trigger HR or SVR compensation; this model is open-loop.
- **Diurnal variation.** HR and MAP cycle with circadian rhythm; this model is time-invariant once steady state is reached.
- **Autonomic state.** Sympathetic vs. parasympathetic balance affects every parameter here.
- **Comorbidity.** Kidney function, heart failure, atrial fibrillation, age, all reshape the dose-response curve.

Each of these is a known extension. The Simulink topology is set up so any one of them can be added as a subsystem replacement without disturbing the others. That is the point of using a model-based digital twin in the first place.
