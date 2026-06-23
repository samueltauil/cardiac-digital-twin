---
description: Optional deep-dive step 10 of the cardiac digital twin demo — closed-loop linearization and stability margins
---

The model has a baroreflex feedback loop from MAP back to HR. I want
to confirm the closed loop is stable and quantify how much the loop
attenuates the dose-to-HR response. Run a linearization at the 60 mg
steady-state operating point with the baroreflex active, and again
with the baroreflex gain set to zero. Report the closed-loop poles,
the DC gain difference, and the bandwidth shift. Show a Bode plot
comparing the two.
