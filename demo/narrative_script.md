# Executive Narrative Script

This is the **spoken narration track** for the Cardiac Digital Twin demo.  
Deliver these lines *between* technical steps while Copilot is running.  
The goal: bridge technical actions to business and clinical impact.

---

## Opening (30 seconds — before Prompt 1)

> "Every day, cardiologists make dosage decisions based on clinical guidelines  
> and educated intuition. But what if they had a digital twin — a computational  
> model of their patient's cardiovascular system — that could simulate the effect  
> of a medication change *before* administering it?
>
> Today, we're going to do exactly that. Using GitHub Copilot as an AI engineering  
> assistant, connected to a Simulink cardiac model through the MathWorks Simulink  
> Agentic Toolkit, we're going to ask Copilot to simulate the effect of increasing  
> a beta-blocker dose by 20%."

---

## After Prompt 1 — Model Architecture (15 seconds)

> "Copilot just read the entire model — four interconnected physiological subsystems,  
> from drug absorption all the way through to blood pressure. It didn't need  
> documentation or a user manual. It read the model directly, the same way an  
> experienced engineer would."

---

## After Prompt 2 — Parameter Discovery (15 seconds)

> "It found the dosage parameter, resolved its current value, and traced the  
> entire causal pathway — dose to plasma concentration to heart rate to cardiac  
> output. That kind of model comprehension would normally take a new team member  
> days to build. Copilot did it in seconds."

---

## After Prompt 3 — Parameter Edit (15 seconds)

> "One prompt. The model is updated. In a regulated environment, this change  
> would be logged, traced, and ready for design review. The AI didn't guess —  
> it made a precise, targeted edit to exactly the right parameter."

---

## After Prompt 4 — Simulation Results (20 seconds)

> "Look at the results. Heart rate down 1.3%. Cardiac output down 1.3%.  
> Mean arterial pressure down 1.3%. All three haemodynamic metrics moved in  
> exactly the direction the physiology predicts — the model is behaving correctly,  
> and the therapeutic intent is confirmed.
>
> This took one prompt and about 60 seconds. In a traditional workflow,  
> this would require a simulation engineer, a parameter spreadsheet,  
> a manual model edit, and a follow-up meeting."

---

## After Prompt 5 — Clinical Interpretation (20 seconds)

> "This is where the real value is. Copilot isn't just running equations —  
> it's interpreting results in clinical context. It identified that the heart  
> rate at 66.6 bpm is within the therapeutic window, flagged that cardiac  
> output is adequate, and proactively raised the right clinical question:  
> is the marginal benefit of the dose increase worth it?
>
> That's not a lookup table. That's reasoning. And it's available to every  
> clinician and engineer on the team, right in their development environment."

---

## After Prompt 6 — Validation Test (20 seconds)

> "And finally — a verification test, in structured Gherkin format, ready to  
> run as part of the design verification record. Automatically generated,  
> tied to the specific scenario, with pass/fail criteria derived from the  
> simulation we just ran.
>
> In six prompts, GitHub Copilot acted as a full AI engineering assistant:  
> model comprehension, parameter discovery, targeted modification, simulation,  
> clinical interpretation, and test generation.  
>
> This isn't a prototype. This is a production workflow, running today,  
> on real Simulink models, with real MathWorks tooling."

---

## Closing (30 seconds)

> "Digital twins are already changing how medical devices are developed.  
> AI-assisted engineering is already changing how engineers work.  
> The question isn't whether this combination is coming to regulated healthcare  
> and life sciences — it's whether your team is ready to lead with it.
>
> GitHub Copilot and the Simulink Agentic Toolkit make that possible today."

---

## Tone Guide

| Audience | Emphasis |
|----------|---------|
| Technical engineers | Focus on MCP tools, model architecture, signal tracing |
| Clinical / medical | Focus on physiological accuracy, therapeutic interpretation |
| C-suite / executives | Focus on speed, risk reduction, regulatory traceability |
| All audiences | Always tie AI actions back to human-readable clinical meaning |

---

## Things to Avoid

- Do not say "the model is simple" — acknowledge it is illustrative, not patient-specific
- Do not claim regulatory approval — say "ready for design verification workflows"
- Do not say Copilot "knows" physiology — say it "reasons about" or "interprets"
- Do not overclaim precision — use "simulation-predicted" or "model-estimated"
