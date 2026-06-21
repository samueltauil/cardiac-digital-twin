# --- front-matter:toml ---
model = "CardiacDigitalTwin.slx"
component = "CardiacDigitalTwin/HeartRateModel"
[inputs]
Concentration = "ConcentrationIn"
[outputs]
HR = "HeartRateOut"
# --- end front-matter ---

Feature: Beta-blocker dose-response on heart rate
  Verifies that increasing metoprolol from 50 mg to 60 mg reduces
  the steady-state heart rate by at least 2 bpm. At PK steady state,
  plasma concentration equals dose (PK gain = 1), so a constant
  concentration input is the equivalent dose at steady state.

Scenario: Baseline 50 mg dose holds heart rate near 63 bpm
  Confirms the model's calibrated response at the current dose.
  Given inputs
    * Concentration = const(50)
  When simulate for 1s in Normal mode
  Then outputs
    * BaselineUpperBound: HR <= 63.1
    * BaselineLowerBound: HR >= 62.9

Scenario: Increased 60 mg dose drops heart rate by at least 2 bpm
  Bound HR at 60 mg between 60.5 and 60.7. Combined with the 50 mg
  lower bound of 62.9, this guarantees a minimum drop of 2.2 bpm.
  Given inputs
    * Concentration = const(60)
  When simulate for 1s in Normal mode
  Then outputs
    * IncreasedDoseUpperBound: HR <= 60.7
    * IncreasedDoseLowerBound: HR >= 60.5
    * NotBelowClamp: HR >= 40
