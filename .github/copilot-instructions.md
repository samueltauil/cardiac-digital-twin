# Cardiac Digital Twin — Copilot Instructions

These instructions apply to every Copilot interaction in this repository.

## Repository context

This repository is a demo showing **GitHub Copilot + Simulink Agentic Toolkit (MCP)**
orchestrating a Simulink cardiac digital twin. The primary scenario is simulating the effect of a
beta-blocker (metoprolol) dosage increase of 20% (50 mg → 60 mg) on key haemodynamic outputs.

The model (`CardiacDigitalTwin.slx`) is a five-subsystem closed-loop Simulink model:

| Subsystem | Input(s) | Output |
|-----------|----------|--------|
| `BetaBlockerPK` | `beta_blocker_dose_mg` (mg) | plasma concentration |
| `HeartRateModel` | plasma concentration + baroreflex correction | heart rate (bpm) |
| `CardiacOutputModel` | heart rate (bpm) | cardiac output (L/min) |
| `BloodPressureModel` | cardiac output (L/min) | mean arterial pressure (mmHg) |
| `BaroreflexController` | mean arterial pressure (mmHg) | HR correction (bpm) (closes loop to HeartRateModel) |

Key workspace parameters (defined in `model/cardiac_params.m`):
- `beta_blocker_dose_mg = 60` — current dose; the demo runs 50 mg vs 60 mg
- `baseline_heart_rate = 75` — drug-free resting HR
- `emax_bpm = 18`, `ec50_mg = 35`, `hill_n = 1.5` — Hill/Emax receptor binding parameters
- `pk_time_constant = 1800` — first-order PK time constant (seconds)
- `stroke_volume_mL = 70`, `svr_mmHg_min_per_L = 18`
- `map_setpoint_mmHg = 94`, `baroreflex_gain = 0.30`, `baroreflex_tau = 60` — closed-loop autonomic feedback

Expected closed-loop steady-state at 50 mg: HR ≈ 67.4 bpm, CO ≈ 4.72 L/min, MAP ≈ 84.9 mmHg.
At 60 mg (+20%): HR ≈ 66.6 bpm, CO ≈ 4.66 L/min, MAP ≈ 83.9 mmHg.
The marginal HR drop is small (~0.9 bpm) because the Hill curve saturates near Emax and the baroreflex partially restores HR.

## Simulink MCP tools available

The following tools are registered via the Simulink Agentic Toolkit MCP server:

| Tool | Purpose |
|------|---------|
| `model_overview` | Describe model hierarchy and subsystems |
| `model_read` | Read block parameters and signal connections |
| `model_edit` | Modify block parameters |
| `model_check` | Run Simulink Advisor checks |
| `model_test` | Run or generate tests (requires Simulink Test) |
| `model_query_params` | Find parameters by name or value |
| `model_resolve_params` | Resolve a parameter to its workspace value |

When a prompt relates to the Simulink model, prefer these tools over general code analysis.

## Code conventions

- MATLAB scripts use `%%` section headers with descriptive titles
- Local functions must be placed **at the end** of script files (MATLAB requirement)
- Simulation output signals are accessed by named field: `simOut.HR_out`, `simOut.CO_out`, `simOut.MAP_out`
- Steady state is defined as the final 10% of the simulation window (`StopTime = 3600` s)
- Validation pass/fail criteria are in `validation/validation_criteria.md`; automation is in `validation/validate_beta_blocker.m`

## Simulink Agentic Toolkit skills

The following skills are installed by the toolkit setup and declared in the demo agent.
They provide domain-specific guidance that augments the MCP tools:

| Skill | Demo usage |
|-------|-----------|
| `simulating-simulink-models` | Prompt 4 — run and compare simulations |
| `testing-simulink-models` | Prompt 6 — generate Gherkin validation test |
| `specifying-plant-models` | Prompt 1 — explore cardiac plant model architecture |
| `specifying-mbd-algorithms` | Prompt 2 — trace PK/PD algorithm through model |
| `building-simulink-models` | Prompt 1 — describe model structure |
| `generate-requirement-drafts` | Prompt 7 — generate formal engineering requirements |

Skills are automatically available after toolkit setup (symlinked to `~/.agents/skills/`).
See `setup/mcp-configuration.md` for setup details.

## Demo delivery

- Live prompt sequence: `demo/live_prompts.md`
- Pre-verified fallback outputs: `demo/scripted_runbook.md`
- Executive narration: `demo/narrative_script.md`
- Pre-demo setup: `setup/preflight_checklist.md`
