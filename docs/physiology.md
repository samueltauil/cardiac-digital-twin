# Physiology and math

!!! info "Before you read"
    This page walks through the four formulas that make the cardiac digital
    twin tick, and the clinical reasoning behind each one. The
    [Quick vocabulary](#quick-vocabulary) below covers every domain term used
    on the page. If you are a clinician new to model-based engineering, skim
    the vocabulary then jump straight to [The four equations](#the-four-equations).
    If you are an engineer new to cardiac physiology, the same vocabulary
    explains the medical terms; the maths is then the easy bit.

---

## Quick vocabulary

| Term | What it means |
|---|---|
| **Beta-blocker** | A class of medication that blocks beta-adrenergic receptors on the heart and blood vessels, slowing the heart and lowering blood pressure. |
| **Metoprolol** | A common, cardioselective beta-blocker (mainly affects the heart, less the lungs). Used for hypertension, angina, and after heart attacks. |
| **Hypertension** | Chronically high blood pressure. Treated to lower the risk of stroke, heart failure, and kidney disease. |
| **Bradycardia** | A resting heart rate below about 60 bpm. May be normal in athletes; concerning if symptomatic. |
| **Plasma concentration** | The amount of drug per unit volume in the blood plasma. Drives the drug's effect. |
| **Pharmacokinetics (PK)** | How drug concentration in the body changes over time after a dose. The "what the body does to the drug" side. |
| **Pharmacodynamics (PD)** | How a given drug concentration produces an effect. The "what the drug does to the body" side. |
| **HR (heart rate)** | Beats per minute. About 60 to 100 at rest in healthy adults. |
| **SV (stroke volume)** | Volume of blood the heart ejects with each beat. About 70 mL at rest. |
| **CO (cardiac output)** | Volume of blood pumped per minute. \(\text{CO} = \text{HR} \times \text{SV}\). About 4 to 5 L/min at rest. |
| **MAP (mean arterial pressure)** | The time-averaged pressure in the arteries. Above 65 mmHg is needed for adequate organ perfusion. |
| **SVR (systemic vascular resistance)** | How much the body's small arteries resist blood flow. Effectively the "afterload" the heart has to pump against. |
| **Cardiac index** | CO normalised by body surface area, used to compare patients of different sizes. About 2.5 to 4 L/min/m² at rest. |
| **BSA (body surface area)** | Roughly 1.7 to 2.0 m² for an adult. |
| **Steady state** | The condition after enough time has passed that the system stops changing. For a one-dose-per-day regimen, this is the long-run plateau. |
| **First-order kinetics** | A change rate proportional to the current value. Produces an exponential approach to a plateau, not a linear ramp. |
| **Time constant (τ)** | The time it takes for a first-order system to reach about 63 % of its final value. After 5τ it is within 1 %. |
| **Half-life** | The time to halve the current value. For first-order kinetics, \(t_{1/2} = \tau \ln 2\). |
| **DC gain** | The steady-state ratio of output to input of a linear filter. A "unity gain" filter eventually outputs whatever it is fed. |
| **Saturation (clamp)** | A non-linear operation that limits a value to a fixed minimum and maximum. Used here as a physiological safety floor on HR. |

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

### 1. Pharmacokinetics: first-order absorption and elimination

\[
\boxed{\;C(s) \;=\; \frac{1}{\tau s + 1}\,D(s)\;}
\]

!!! abstract "What this means in plain language"
    After you take the metoprolol tablet, the drug level in your blood does
    not jump to its final value immediately. It rises smoothly along an
    exponential curve and settles toward a plateau equal to the dose. The
    time constant \(\tau\) tells you how fast that happens.

The equation above is in Laplace transform notation, the standard mathematical shorthand for linear time-invariant systems. `C(s)` is the plasma concentration over time, written as a Laplace transform; `D(s)` is the dose, similarly transformed. In Simulink it is one `Transfer Fcn` block with numerator `[1]` and denominator `[pk_time_constant 1]`.

In the time domain, with a step input \(D(t) = D\) for \(t \geq 0\):

\[
C(t) \;=\; D\!\left(1 - e^{-t/\tau}\right)
\]

A few properties matter for the demo.

The DC gain is one: \(\lim_{t \to \infty} C(t) = D\). At steady state the plasma concentration *equals* the dose value. This is what lets the validation test drive `HeartRateModel` directly with `const(50)` and `const(60)` and still represent the full-model 50 mg to 60 mg comparison.

The settling time is about 5\(\tau\) (9000 s). The simulation `StopTime` of 3600 s catches roughly 86 % of the asymptote (2 time constants); the full-validation runs extend to 9000 s.

The half-life is \(\tau \ln 2\), about 1247 s or 20.8 minutes. Metoprolol's *clinical* half-life is 3 to 7 hours; the demo uses 30 minutes to keep simulation time short while preserving the exponential *shape* of the response.

!!! note "On the unit treatment"
    The PK block has unity gain and no explicit unit conversion. We interpret
    *plasma concentration* in this model as a normalised quantity that takes the
    same numerical value as the dose. A real PK model would divide by volume of
    distribution and account for absorption, distribution, and elimination
    rates separately. Those refinements would not change the *shape* of the
    dose-response surface this demo demonstrates.

### 2. Chronotropic response: linear gain with safety clamp

\[
\boxed{\;\text{HR}(t) \;=\; \mathrm{clamp}\!\bigl(\text{HR}_0 - k_\beta \cdot C(t),\ \ 40,\ 180\bigr)\;}
\]

!!! abstract "What this means in plain language"
    Heart rate starts at the drug-free resting value (75 bpm) and is reduced
    by a fixed amount per unit of drug in the blood. The "clamp" guarantees
    the model never returns a heart rate outside the physiological range of
    40 to 180 bpm, even if a wildly out-of-range dose is requested.

At steady state this collapses to a simple line:

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

The 0.24 bpm/mg gain was chosen so the standard 50 mg/day metoprolol succinate dose produces about a 12 bpm reduction, consistent with clinical practice.

The linear model fails outside the therapeutic range, which is why the saturation block is there. It is a defensive guard that does not activate in normal use.

- Lower bound `40`: physiological floor for resting HR in a non-pacemaker patient.
- Upper bound `180`: tachycardia ceiling. Would only matter if the dose were negative.

The clamp activates at \(D = (75-40)/0.24 = 145.8\) mg, well beyond the therapeutic range. This sets the *validity domain* of the linear approximation, which the performance requirement (REQ_CDT_002) explicitly bounds to \([0, 145]\) mg.

### 3. Cardiac output: a Fick-like decomposition

\[
\boxed{\;\text{CO}\ [\text{L/min}] \;=\; \text{HR}\ [\text{bpm}] \cdot \frac{\text{SV}\ [\text{mL}]}{1000}\;}
\]

!!! abstract "What this means in plain language"
    The total amount of blood the heart pumps per minute equals the number of
    beats per minute times the volume per beat. Simple multiplication. The
    "/1000" converts millilitres into litres.

At baseline (\(\text{HR}_0\) with no drug, \(\text{SV} = 70\)):

\[
\text{CO}_0 \;=\; 75 \cdot \frac{70}{1000} \;=\; 5.25\ \text{L/min}
\]

which is a textbook adult resting cardiac output.

Stroke volume is held constant in this model. Beta-blockers' impact on SV is small and goes in two directions at once: a slower heart has more time to fill (slightly *increasing* SV) but contracts a little less forcefully (slightly *decreasing* SV). For a first-order picture, treating SV as fixed is honest. A more elaborate model would add the **Frank-Starling relationship**, where SV depends on how much blood enters the heart before each beat.

### 4. Mean arterial pressure: afterload identity

\[
\boxed{\;\text{MAP}\ [\text{mmHg}] \;=\; \text{CO}\ [\text{L/min}] \cdot \text{SVR}\ [\text{mmHg}\cdot\text{min/L}]\;}
\]

!!! abstract "What this means in plain language"
    Average blood pressure equals the rate of flow times the resistance the
    flow encounters. Same principle as voltage equalling current times
    resistance in an electrical circuit. Halve the flow with no change in
    resistance and the pressure halves.

The familiar haemodynamic identity, with SVR held constant. Beta-blockers have minimal direct vasoactive effect at this dose; the MAP reduction they produce comes through CO, not through vessel dilation.

At baseline:

\[
\text{MAP}_0 \;=\; 5.25 \cdot 18 \;=\; 94.5\ \text{mmHg}
\]

which sits inside the normal adult resting range of 70 to 105 mmHg.

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

Every result in this demo has a **closed-form prediction** that can be checked against the simulation. A closed-form prediction is a formula you can evaluate with a calculator, with no need to run the model.

- The Gherkin test bounds are derived from \(\text{HR}_{ss} = 75 - 0.24 \cdot D\).
- The expected-output banner in `cardiac_params.m` is generated from the same formula and printed at startup.
- The validation suite (`validation/validate_beta_blocker.m`) cross-checks simulation outputs against the analytical expectations.

This is the discipline that makes the model a *reference implementation* rather than a black box. Every output is auditable: any reader can plug numbers into the four formulas and verify the result themselves.

---

## What the demo deliberately leaves out

Honest scoping matters. The v1 model omits the following, and the [Advanced physiology (Phase 2)](advanced-physiology.md) page covers the first three with concrete v2 implementations:

- **Receptor-binding nonlinearity.** \(k_\beta\) is constant in v1. v2 replaces it with a Hill/Emax expression so each extra milligram has less effect as binding saturates.
- **Baroreflex feedback.** Falling MAP would normally trigger autonomic compensation that nudges HR up. v1 is open-loop; v2 adds a `BaroreflexController` subsystem that closes the loop from MAP back to HR.
- **Patient variability.** v1 is one nominal patient. v2 ships a Monte Carlo cohort of 100 virtual patients with a PRCC sensitivity tornado.
- **Diurnal variation.** Real HR and MAP cycle with the circadian rhythm. Neither v1 nor v2 models this.
- **Autonomic state.** Sympathetic versus parasympathetic balance affects every parameter here. v2's baroreflex captures part of this loop but not the full autonomic dynamics.
- **Comorbidity.** Kidney function, heart failure, atrial fibrillation, age. Each reshapes the dose-response curve and is out of scope for both versions.

The Simulink topology is set up so any of these can be added as a subsystem replacement without disturbing the others. That is the point of using a model-based digital twin in the first place, and is exactly the route Phase 2 follows.

*[HR]: heart rate, measured in beats per minute (bpm)
*[CO]: cardiac output, the volume of blood the heart pumps per minute (L/min)
*[SV]: stroke volume, the volume of blood ejected per heartbeat (mL/beat)
*[MAP]: mean arterial pressure, the time-averaged arterial blood pressure (mmHg)
*[SBP]: systolic blood pressure, the peak pressure during a heartbeat
*[SVR]: systemic vascular resistance, how much the body's blood vessels resist blood flow (mmHg·min/L)
*[PK]: pharmacokinetics, how the body absorbs, distributes, and eliminates a drug over time
*[PD]: pharmacodynamics, how a drug affects the body once it is there
*[bpm]: beats per minute
*[mmHg]: millimetres of mercury, the standard unit for blood pressure
*[mg]: milligram
*[mL]: millilitre
*[L]: litre
*[BSA]: body surface area (about 1.7 to 2.0 m² in an adult)
*[COPD]: chronic obstructive pulmonary disease
*[DC gain]: the steady-state ratio of output to input of a linear filter
