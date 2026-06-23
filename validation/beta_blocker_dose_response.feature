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
  Confirms the open-loop Hill response at the current baseline dose.
  Given inputs
    * Concentration = const(50)
    * BaroreflexIn  = const(0)
  When simulate for 1s in Normal mode
  Then outputs
    * BaselineUpperBound: HR <= 63.9
    * BaselineLowerBound: HR >= 63.4

Scenario: Increased 60 mg dose still drops HR despite Hill saturation
  Bound HR at 60 mg between 62.3 and 62.8. Combined with the 50 mg
  lower bound of 63.4, this guarantees a minimum drop of 0.6 bpm.
  The drop is small because the Hill curve is already past EC50.
  Given inputs
    * Concentration = const(60)
    * BaroreflexIn  = const(0)
  When simulate for 1s in Normal mode
  Then outputs
    * IncreasedDoseUpperBound: HR <= 62.8
    * IncreasedDoseLowerBound: HR >= 62.3
    * NotBelowClamp: HR >= 40
