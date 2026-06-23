---
description: Step 6 of the cardiac digital twin demo — generate a Gherkin validation test
---

Write a Gherkin-style test scenario that verifies the cardiac model
correctly shows a reduction in heart rate when beta-blocker dose is
increased from 50 mg to 60 mg. The test should check that
steady-state heart rate decreases by at least 0.5 bpm. Because the
Hill/Emax response saturates, drive the `HeartRateModel` subsystem
in open-loop with `BaroreflexIn = const(0)` to isolate the drug effect.
