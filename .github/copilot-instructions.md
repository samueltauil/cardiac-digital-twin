# Cardiac Digital Twin — Copilot Instructions

These instructions apply to every Copilot interaction in this repository.

## Repository context

This repository is a conference demo showing **GitHub Copilot + Simulink Agentic Toolkit (MCP)**
orchestrating a Simulink cardiac digital twin. The primary scenario is simulating the effect of a
beta-blocker (metoprolol) dosage increase of 20% (50 mg → 60 mg) on key haemodynamic outputs.

The model (`CardiacDigitalTwin.slx`) is a four-subsystem Simulink model:

| Subsystem | Input | Output |
|-----------|-------|--------|
| `BetaBlockerPK` | `beta_blocker_dose_mg` (mg) | plasma concentration |
| `HeartRateModel` | plasma concentration | heart rate (bpm) |
| `CardiacOutputModel` | heart rate (bpm) | cardiac output (L/min) |
| `BloodPressureModel` | cardiac output (L/min) | mean arterial pressure (mmHg) |

Key workspace parameters (defined in `model/cardiac_params.m`):
- `beta_blocker_dose_mg = 50` — current dose; the demo changes this to 60
- `baseline_heart_rate = 75` — drug-free resting HR
- `beta_hr_sensitivity = 0.24` — bpm reduction per mg of metoprolol
- `pk_time_constant = 1800` — first-order PK time constant (seconds)
- `stroke_volume_mL = 70`, `svr_mmHg_min_per_L = 18`

Expected steady-state results at 50 mg: HR ≈ 63 bpm, CO ≈ 4.41 L/min, MAP ≈ 79.4 mmHg.

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

## Demo delivery

- Live prompt sequence: `demo/live_prompts.md`
- Pre-verified fallback outputs: `demo/scripted_runbook.md`
- Executive narration: `demo/narrative_script.md`
- Pre-demo setup: `setup/preflight_checklist.md`
