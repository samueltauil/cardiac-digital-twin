# Requirements

A digital twin without requirements is a simulator. A digital twin *with* requirements, and with traceability from each requirement to the model element that implements it, is an **engineering artifact**.

This page documents the three requirements Copilot drafts in Prompt 7, and explains why each one is shaped the way it is.

---

## The artifact

File: [`CardiacDigitalTwin_Requirements.slreqx`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/CardiacDigitalTwin_Requirements.slreqx).

Created via Requirements Toolbox (`slreq.new`, `slreq.add`, `slreq.createLink`). Three top-level requirements with parent and child relationships.

```mermaid
flowchart TD
    REQ001[REQ_CDT_001<br/>System dose-response]
    REQ002[REQ_CDT_002<br/>Performance: HR formula]
    REQ003[REQ_CDT_003<br/>Safety: minimum CO]
    REQ001 --> REQ002
    REQ001 --> REQ003

    REQ001 -.implements.- PK[BetaBlockerPK]
    REQ001 -.implements.- HRM[HeartRateModel]
    REQ002 -.implements.- HRM
    REQ003 -.implements.- COM[CardiacOutputModel]
```

All three are marked `draft` and `auto-generated` in their keyword set. They are the *starting point* for a human reviewer, not the finished article.

---

## REQ_CDT_001. System dose-response

!!! abstract "EARS pattern: Event-driven"
    **When** the prescribed beta-blocker dose (`beta_blocker_dose_mg`) increases
    from 50 mg to 60 mg, the cardiac digital twin **shall** reduce the
    steady-state heart rate by at least 2 bpm.

**Rationale.** The digital twin produces a clinically directionally-correct chronotropic response to dose escalation, supporting its use as a decision-support tool for cardiologist titration review.

**Trace links** (`Implement`):

- `CardiacDigitalTwin:2` (`BetaBlockerPK`). PK stage that produces the steady-state plasma concentration.
- `CardiacDigitalTwin:3` (`HeartRateModel`). Chronotropic stage that converts concentration into HR reduction.

**Verification.** [`validation/beta_blocker_dose_response.feature`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/beta_blocker_dose_response.feature), passing (5 of 5 assessments).

**Why event-driven EARS?** The requirement is *conditional on an event* (a dose change). Ubiquitous wording (*"the system shall reduce HR…"*) would read as if it were always reducing HR; event-driven framing makes the trigger explicit.

---

## REQ_CDT_002. Performance: HR formula

!!! abstract "EARS pattern: Ubiquitous"
    At steady state, the cardiac digital twin **shall** compute heart rate as
    `baseline_heart_rate` (75 bpm) minus `beta_hr_sensitivity` (0.24 bpm/mg)
    times `beta_blocker_dose_mg`, within \(\pm 0.5\) bpm tolerance, for any
    dose in the range `[0 mg, 145 mg]`.

**Rationale.** Pins the model's chronotropic gain to a calibrated, clinically plausible response (about 12 bpm reduction at 50 mg metoprolol succinate) and bounds the validity domain of the linear approximation.

**Trace links:**

- `CardiacDigitalTwin:3` (`HeartRateModel`). The subsystem that implements the formula.

**Why \(\pm 0.5\) bpm?** The simulation's first-order PK takes about 5\(\tau\) (9000 s) to settle to within 0.7 % of the asymptote. The 0.5 bpm tolerance covers both solver settling and any small numerical drift, while still being tight enough to detect a real calibration error.

**Why the [0, 145] mg ceiling?** The HR saturation clamp activates at \(75 - 0.24 \cdot 145.8 = 40\) bpm. Beyond that dose the formula is no longer representative. The requirement explicitly says so.

**Why ubiquitous EARS?** This is an always-true property of the model, not a response to a trigger. Ubiquitous framing communicates "invariant" better than event-driven framing would.

---

## REQ_CDT_003. Safety: minimum cardiac output

!!! abstract "EARS pattern: Unwanted-behaviour"
    **If** the prescribed dose lies within the therapeutic range
    `[0 mg, 100 mg]`, **then** the cardiac digital twin **shall** maintain
    steady-state cardiac output at or above 4.0 L/min.

**Rationale.** The digital twin flags any dosing recommendation that would push the simulated patient below the clinical perfusion threshold, preventing the tool from endorsing a haemodynamically unsafe titration.

**Trace links:**

- `CardiacDigitalTwin:4` (`CardiacOutputModel`). The subsystem whose output the requirement constrains.

**Why 4.0 L/min?** It corresponds to a cardiac index of about 2.0 L/min/m\(^2\) for a typical adult (BSA about 2.0 m\(^2\)), the conventional lower bound of adequate resting perfusion. Below this, organ delivery starts to be compromised.

**Why unwanted-behaviour EARS?** Safety constraints map naturally to *"if condition, then response"* phrasing. It is the canonical pattern for expressing a guard.

### The verification gap

REQ_CDT_003 is intentionally a **failing requirement at the boundary** in the current model:

\[
\begin{aligned}
\text{HR}_{100\text{mg}} &= 75 - 0.24 \cdot 100 = 51\ \text{bpm} \\
\text{CO}_{100\text{mg}} &= 51 \cdot 70 / 1000 = 3.57\ \text{L/min}
\end{aligned}
\]

3.57 is below 4.0, so the safety floor is **breached** at 100 mg under the current `stroke_volume_mL = 70` assumption.

This is the kind of finding the cardiologist review must address:

- Tighten the dose-range bound in the requirement (for example to 80 mg).
- Refine the SV model so that compensatory mechanisms preserve CO above the safety floor.
- Accept the finding and document it as a known limitation.

Either way, the requirement *did its job*: it identified an unsafe operating region before the digital twin was used for any clinical recommendation. That is the whole point of having safety requirements traced to verification.

---

## The link set

```
Source                                Type        Destination
─────────────────────────────────── ────────── ──────────────
CardiacDigitalTwin:2 (BetaBlockerPK)  Implement   REQ_CDT_001
CardiacDigitalTwin:3 (HeartRateModel) Implement   REQ_CDT_001
CardiacDigitalTwin:3 (HeartRateModel) Implement   REQ_CDT_002
CardiacDigitalTwin:4 (CardiacOutputModel) Implement   REQ_CDT_003
```

Direction is intentionally **model element to requirement**. This is the Requirements Toolbox convention: the implementer points at what it implements.

When you open the requirement set in MATLAB:

```matlab
slreq.open('CardiacDigitalTwin_Requirements')
```

…each requirement shows up in the Requirements Editor with an `Implements` arrow rendered alongside the source block in the Simulink canvas.

---

## What Copilot does differently from a template generator

A boilerplate template generator would produce phrasing like *"the system shall not exceed 180 bpm"*. Copilot's draft is structurally different.

Numeric values are typed with their workspace variables. Instead of bare numbers, requirements reference *`beta_hr_sensitivity` (0.24 bpm/mg)*. That makes the requirement legible *and* makes it survive a future re-calibration without becoming stale.

Validity domains are explicit. REQ_CDT_002 bounds the dose range to [0, 145] mg, derived from where the saturation clamp activates. A template wouldn't compute that derivation.

Known limitations are surfaced, not hidden. REQ_CDT_003 calls out the boundary failure at 100 mg in its own Description. Most auto-generated requirements try to look like they pass; this one tells you exactly where it does not.

The result is a requirement set a human reviewer can engage with: challenge the bounds, refine the rationale, baseline the wording. Not a plausible-looking artifact that is actually empty.

---

## Promoting drafts to baselined requirements

The `draft` keyword on every requirement is a checkpoint. The recommended workflow:

1. Review each requirement in the Requirements Editor.
2. Adjust wording, tolerances, and trace links as needed.
3. Verify the trace links by opening each subsystem and confirming the *Requirements* badge appears.
4. Remove the `draft` keyword.
5. Save and tag the `.slreqx` file with the model version it was baselined against.

After baselining, requirement IDs are *frozen*. Future Copilot prompts add new IDs (`REQ_CDT_004` and onward). They never renumber or overwrite an existing baseline.
