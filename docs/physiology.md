# Physiology and math

!!! info "Before you read"
    This page walks through the formulas that make the cardiac digital
    twin tick, and the clinical reasoning behind each one. The
    [Quick vocabulary](#quick-vocabulary) below covers every domain term used
    on the page. If you are a clinician new to model-based engineering, skim
    the vocabulary then jump straight to [The five equations](#the-five-equations).
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
| \(E_{\max}\) | `emax_bpm` | 18 | bpm | Maximum drug-induced HR reduction |
| \(EC_{50}\) | `ec50_mg` | 35 | mg | Concentration for half-maximal effect |
| \(n\) | `hill_n` | 1.5 | — | Hill coefficient (binding cooperativity) |
| \(\text{SV}\) | `stroke_volume_mL` | 70 | mL/beat | Resting stroke volume (constant) |
| \(\text{SVR}\) | `svr_mmHg_min_per_L` | 18 | mmHg·min/L | Systemic vascular resistance |
| \(\text{MAP}^*\) | `map_setpoint_mmHg` | 94 | mmHg | Baroreflex MAP set-point |
| \(k_{\text{baro}}\) | `baroreflex_gain` | 0.30 | bpm/mmHg | Baroreflex feedback gain |
| \(\tau_{\text{baro}}\) | `baroreflex_tau` | 60 | s | Baroreflex first-order lag |

Workspace parameters live in [`model/cardiac_params.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/cardiac_params.m) and are loaded by `setup/startup.m`.

---

## The five equations

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

The DC gain is one: \(\lim_{t \to \infty} C(t) = D\). At steady state the plasma concentration *equals* the dose value. This is what lets the validation test drive `HeartRateModel` directly with `const(50)` and `const(60)` on its concentration input — holding `BaroreflexIn` at `const(0)` to isolate the open-loop drug effect — and still represent the 50 mg to 60 mg forward-path comparison.

The settling time is about 5\(\tau\) (9000 s). The simulation `StopTime` of 3600 s catches roughly 86 % of the asymptote (2 time constants); the full-validation runs extend to 9000 s.

The half-life is \(\tau \ln 2\), about 1247 s or 20.8 minutes. Metoprolol's *clinical* half-life is 3 to 7 hours; the demo uses 30 minutes to keep simulation time short while preserving the exponential *shape* of the response.

!!! note "On the unit treatment"
    The PK block has unity gain and no explicit unit conversion. We interpret
    *plasma concentration* in this model as a normalised quantity that takes the
    same numerical value as the dose. A real PK model would divide by volume of
    distribution and account for absorption, distribution, and elimination
    rates separately. Those refinements would not change the *shape* of the
    dose-response surface this demo demonstrates.

### 2. Chronotropic response: Hill/Emax binding with baroreflex and safety clamp

\[
\boxed{\;\text{HR}(t) \;=\; \mathrm{clamp}\!\left(\text{HR}_0 - E_{\max}\frac{C(t)^n}{EC_{50}^n + C(t)^n} + \Delta\text{HR}_{\text{baro}}(t),\ \ 40,\ 180\right)\;}
\]

!!! abstract "What this means in plain language"
    Heart rate starts at the drug-free resting value (75 bpm). The drug pulls
    it down, but not in a straight line: as the dose climbs, each extra
    milligram does less, because the beta receptors on the pacemaker cells
    progressively fill up. The baroreflex term then nudges the rate back up
    when blood pressure falls. The "clamp" guarantees the model never returns
    a heart rate outside the physiological range of 40 to 180 bpm.

The drug term is the standard **Hill/Emax** equation, implemented in the `HillEquation` Fcn block. \(E_{\max} = 18\) bpm is the most the drug can ever lower the rate; \(EC_{50} = 35\) mg is the concentration that delivers half of that; \(n = 1.5\) is the Hill coefficient that sets how sharply the curve turns over. Because the response saturates, the marginal effect of a 50 → 60 mg increase is small — that is the central physiological point the demo makes.

The open-loop drug effect alone (baroreflex held at zero) is:

| Dose | Drug-only HR | Reference HR (clinical) |
|---:|:---:|:---:|
| 25 mg | 68.2 bpm | 67 to 70 |
| 50 mg | 63.6 bpm | 60 to 65 |
| 100 mg | 60.1 bpm | 55 to 62 |

The \(E_{\max}\), \(EC_{50}\), and \(n\) values were chosen so the standard 50 mg/day dose sits on the steep part of the curve while 100 mg already approaches the ceiling, consistent with the diminishing returns seen clinically.

- Lower bound `40`: physiological floor for resting HR in a non-pacemaker patient.
- Upper bound `180`: tachycardia ceiling. Would only matter under extreme baroreflex correction.

At therapeutic doses the clamp never engages: even the closed-loop rate stays well above 60 bpm. The clamp marks the *validity domain* of the model, which the performance requirement (REQ_CDT_002) bounds to \([0, 145]\) mg.

### 2b. Baroreflex feedback: the autonomic loop

\[
\boxed{\;\tau_{\text{baro}}\,\dot{\Delta\text{HR}}_{\text{baro}} \;=\; k_{\text{baro}}\,(\text{MAP}^* - \text{MAP}) - \Delta\text{HR}_{\text{baro}}\;}
\]

!!! abstract "What this means in plain language"
    The body does not let blood pressure drift freely. Pressure sensors in the
    arteries (baroreceptors) detect when mean arterial pressure falls below its
    set-point and signal the heart to speed up to compensate. This term adds
    that reflex back into the heart-rate equation, closing the loop.

When the drug lowers MAP below the set-point \(\text{MAP}^* = 94\) mmHg, the baroreflex adds a positive HR correction \(k_{\text{baro}}(\text{MAP}^* - \text{MAP})\), filtered through a first-order lag \(\tau_{\text{baro}} = 60\) s. This partially restores heart rate and keeps blood pressure from falling unrealistically far. The loop also attenuates the dose-to-HR gain: a [linearization analysis](advanced-physiology.md) shows the open-loop DC gain of −0.152 bpm/mg drops to −0.111 bpm/mg closed-loop, about a 27 % reduction, with the closed loop remaining stable (dominant pole at −0.023 rad/s).

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

## Closed-loop steady-state dose response

Heart rate no longer has a one-line closed form: the Hill term is nonlinear and the baroreflex couples HR to MAP, so the steady-state HR is the fixed point of the closed loop. The downstream stages stay linear, so once HR settles, CO and MAP follow directly:

\[
\begin{aligned}
\text{HR}_{ss}(D) &= \text{HR}_0 - E_{\max}\frac{C^n}{EC_{50}^n + C^n} + k_{\text{baro}}(\text{MAP}^* - \text{MAP}_{ss}) \quad\text{(solved self-consistently, } C = D) \\
\text{CO}_{ss}(D) &= \frac{\text{HR}_{ss}(D) \cdot 70}{1000} \\
\text{MAP}_{ss}(D) &= \frac{\text{HR}_{ss}(D) \cdot 70 \cdot 18}{1000}
\end{aligned}
\]

Numerically, for the demo's two doses (full closed-loop model):

| Dose | \(\text{HR}_{ss}\) | \(\text{CO}_{ss}\) | \(\text{MAP}_{ss}\) |
|---:|:---:|:---:|:---:|
| 50 mg | 67.4 bpm | 4.72 L/min | 84.9 mmHg |
| 60 mg | 66.6 bpm | 4.66 L/min | 83.9 mmHg |

The proportional change is still identical across all three outputs:

\[
\frac{\Delta\text{HR}}{\text{HR}_{50}}
\;=\; \frac{\Delta\text{CO}}{\text{CO}_{50}}
\;=\; \frac{\Delta\text{MAP}}{\text{MAP}_{50}}
\;\approx\; \frac{-0.85}{67.4}
\;\approx\; -1.3\,\%
\]

This survives the nonlinearity because the downstream coupling is still linear (`CO = HR × const`, `MAP = CO × const`): whatever percent change the Hill curve and baroreflex produce in HR propagates identically through both downstream stages. The change is small — about a third of what a naive linear gain would predict — precisely because the Hill curve is near saturation and the baroreflex claws back part of the drop.

---

## Why the analytics matter

Every result in this demo has a **closed-form or analytically-verified prediction** that can be checked against the simulation. The PK, cardiac-output, and blood-pressure stages are closed-form; the closed-loop HR fixed point is verified by linearization and by the saturating Hill curve.

- The Gherkin test bounds are derived from the open-loop Hill response (`BaroreflexIn = const(0)`): 63.4 to 63.9 bpm at 50 mg, 62.3 to 62.8 bpm at 60 mg.
- The expected-output banner in `cardiac_params.m` prints the closed-loop steady-state targets at startup.
- The validation suite (`validation/validate_beta_blocker.m`) cross-checks simulation outputs against the analytical expectations.

This is the discipline that makes the model a *reference implementation* rather than a black box. Every output is auditable: the forward path can be checked by hand, and the closed-loop behaviour is pinned down by the linearization in [Advanced physiology](advanced-physiology.md).

---

## What the model includes and leaves out

Honest scoping matters. The model captures three effects that a naive linear twin would miss, each covered in detail on the [Advanced physiology](advanced-physiology.md) page:

- **Receptor-binding nonlinearity.** A Hill/Emax expression replaces any constant gain, so each extra milligram has less effect as binding saturates. This is the dominant reason the 50 → 60 mg change is small.
- **Baroreflex feedback.** Falling MAP triggers autonomic compensation that nudges HR back up. The `BaroreflexController` subsystem closes the loop from MAP back to HR.
- **Patient variability.** A Monte Carlo cohort of 100 virtual patients with a PRCC sensitivity tornado quantifies how parameter spread reshapes the response.

It still leaves the following out, by design:

- **Two-compartment PK.** The PK stage is a single first-order lag. A clinical model would separate absorption, distribution, and elimination, and divide by volume of distribution.
- **Diurnal variation.** Real HR and MAP cycle with the circadian rhythm. Not modelled.
- **Full autonomic dynamics.** The baroreflex captures part of the sympathetic/parasympathetic loop, but not the complete autonomic state.
- **Comorbidity.** Kidney function, heart failure, atrial fibrillation, age. Each reshapes the dose-response curve and is out of scope.

The Simulink topology is set up so any of these can be added as a subsystem replacement without disturbing the others. That is the point of using a model-based digital twin in the first place.

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
