# Reference

Parameter values, MCP tools, prompt files, and the file map. Everything you would want to look up quickly without re-reading the narrative pages.

---

## Parameter reference

All parameters live in [`model/cardiac_params.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/cardiac_params.m).

| Variable | Default | Units | Used in | Notes |
|---|---:|---|---|---|
| `beta_blocker_dose_mg` | 50 | mg | `BetaBlockerDose` Constant | The dose the demo changes in Prompt 3. |
| `pk_time_constant` | 1800 | s | `BetaBlockerPK / PKTransferFcn` denominator | 30 min effective time constant. |
| `baseline_heart_rate` | 75 | bpm | `HeartRateModel / BaselineHR` | Drug-free resting HR. |
| `beta_hr_sensitivity` | 0.24 | bpm/mg | `HeartRateModel / BetaSensitivity` Gain | Chronotropic gain. |
| `stroke_volume_mL` | 70 | mL/beat | `CardiacOutputModel / StrokeVolume` | Constant in this demo. |
| `svr_mmHg_min_per_L` | 18 | mmHg·min/L | `BloodPressureModel / SVRGain` | Constant in this demo. |

Derived constants (printed at startup, not used by Simulink):

| Quantity | Formula | Value at default dose |
|---|---|---:|
| `expected_HR_baseline_bpm` | \(\text{HR}_0 - k_\beta \cdot D\) | 63.0 bpm |
| `expected_CO_baseline_Lmin` | \(\text{HR}_{ss} \cdot \text{SV} / 1000\) | 4.41 L/min |
| `expected_MAP_baseline_mmHg` | \(\text{CO}_{ss} \cdot \text{SVR}\) | 79.4 mmHg |

---

## Model configuration

| Setting | Value | Set in |
|---|---|---|
| Solver | `ode45` | `create_cardiac_model.m` |
| Solver type | Variable-step | `create_cardiac_model.m` |
| `StopTime` | `3600` (s) by default; overridden to `9000` in full-validation runs | `create_cardiac_model.m` |
| `MaxStep` | `10` (s) | `create_cardiac_model.m` |
| `EnablePacing` | `off` by default; `on` during the dashboard | toggled by `realtime_dashboard.m` |
| `PaceRate` | `0.005` (wall sec per sim sec) when pacing is on | `realtime_dashboard.m` |

---

## MCP tools used by the demo

The `matlab-simulink` MCP server (defined in `.vscode/mcp.json`) exposes both Simulink graph tools and MATLAB code tools. Every prompt in the demo routes to one or more.

### Simulink tools

| Tool | Used in | Purpose |
|---|---|---|
| `model_overview` | Prompt 1 | Subsystem hierarchy and interface summary. |
| `model_read` | Prompts 1, 2 | Block topology, connections, computed expressions. |
| `model_query_params` | Prompt 2 | Random access to block parameters not in `model_read`. |
| `model_resolve_params` | Prompts 2, 3 | Resolve workspace variables to numeric values. |
| `model_edit` | Prompt 3 (parameter form) | Structural and parameter changes to the model. |
| `model_test` | Prompt 6 | Gherkin-driven Simulink Test harness creation and run. |
| `model_check` | (optional) | Lint for unconnected ports, dangling lines, Stateflow issues. |

### MATLAB tools

| Tool | Used in | Purpose |
|---|---|---|
| `evaluate_matlab_code` | Prompts 3, 4, 7 | Direct MATLAB execution in the shared session (`assignin`, `sim`, `slreq.*`). |
| `run_matlab_file` | Setup, demo, dashboard | Execute a `.m` script end-to-end. |
| `run_matlab_test_file` | (optional) | Run a `matlab.unittest.TestCase` via `runtests`. |
| `check_matlab_code` | Pre-commit | Static analysis on a `.m` file. |
| `detect_matlab_toolboxes` | Diagnostics | List installed toolboxes when a feature requires one. |

The tools are loaded automatically when Copilot is invoked in Agent mode with the workspace-level `.vscode/mcp.json` active.

---

## Prompt files

Each prompt is a reusable Copilot slash command, stored in [`.github/prompts/`](https://github.com/samueltauil/cardiac-digital-twin/tree/main/.github/prompts).

| File | Slash command | Demo step |
|---|---|---|
| `01-explore-model.prompt.md` | `/01-explore-model` | Prompt 1. Architecture overview |
| `02-find-dosage-parameter.prompt.md` | `/02-find-dosage-parameter` | Prompt 2. Locate dose parameter |
| `03-apply-dose-change.prompt.md` | `/03-apply-dose-change` | Prompt 3. Apply +20 % change |
| `04-run-simulation.prompt.md` | `/04-run-simulation` | Prompt 4. Run and compare |
| `05-interpret-clinical-impact.prompt.md` | `/05-interpret-clinical-impact` | Prompt 5. Clinical interpretation |
| `06-generate-validation-test.prompt.md` | `/06-generate-validation-test` | Prompt 6. Gherkin test |
| `07-generate-requirements.prompt.md` | `/07-generate-requirements` | Prompt 7. Engineering requirements |
| `08-realtime-dashboard.prompt.md` | `/08-realtime-dashboard` | Prompt 8. Real-time dashboard |

---

## File map

| Path | What it is |
|---|---|
| [`model/cardiac_params.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/cardiac_params.m) | Workspace parameters. |
| [`model/create_cardiac_model.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/create_cardiac_model.m) | Builds `CardiacDigitalTwin.slx`. |
| [`model/run_simulation.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/model/run_simulation.m) | Headless run and comparison plot. |
| [`validation/beta_blocker_dose_response.feature`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/beta_blocker_dose_response.feature) | Gherkin verification test. |
| [`validation/validate_beta_blocker.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/validate_beta_blocker.m) | MATLAB validation suite. |
| [`validation/validation_criteria.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/validation/validation_criteria.md) | 10 pass/fail acceptance criteria. |
| [`demo/live_prompts.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/demo/live_prompts.md) | The 8-prompt narrative. |
| [`demo/scripted_runbook.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/demo/scripted_runbook.md) | Pre-verified fallback outputs. |
| [`demo/narrative_script.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/demo/narrative_script.md) | Executive narration. |
| [`demo/realtime_dashboard.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/demo/realtime_dashboard.m) | Live `uifigure` dashboard. |
| [`CardiacDigitalTwin_Requirements.slreqx`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/CardiacDigitalTwin_Requirements.slreqx) | Engineering requirements artifact. |
| [`setup/startup.m`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/setup/startup.m) | MATLAB session initialiser. |
| [`setup/mcp-configuration.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/setup/mcp-configuration.md) | MCP setup guide. |
| [`setup/preflight_checklist.md`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/setup/preflight_checklist.md) | Pre-demo verification. |

---

## What is and is not committed

| Pattern | Status | Why |
|---|---|---|
| `model/*.m`, `validation/*.m`, `demo/*.m` | tracked | Source of truth (scripts, not binaries). |
| `*.feature` | tracked | Gherkin tests are hand-authored. |
| `*.slreqx` | tracked | Engineering requirements are hand-authored. |
| `*.md`, `mkdocs.yml`, `docs/**` | tracked | Documentation. |
| `.github/**`, `.vscode/mcp.json` | tracked | Repo-level Copilot and MCP configuration. |
| `CardiacDigitalTwin.slx` | **gitignored** | Built by `create_cardiac_model.m`. |
| `*.slxc`, `slprj/`, `*.mat` | **gitignored** | Build and cache artifacts. Regenerated on every build. |
| `*.autosave`, `*~mdl.slmx`, `*_harnessInfo.xml` | **gitignored** | Transient Simulink editor and test files. |

The result: the entire model and every engineering artifact are reproducible from a clean clone. Run `startup.m`, and the `.slx`, the harness, the `slprj/` cache, and any required parameter state are all regenerated locally.

---

## Building this documentation site

```bash
pip install -r docs-requirements.txt
mkdocs serve          # local preview at http://127.0.0.1:8000
mkdocs build          # produce a static site in ./site/
```

The site uses [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/), [Mermaid](https://mermaid.js.org/) for diagrams, and MathJax for formulas. All configuration is in [`mkdocs.yml`](https://github.com/samueltauil/cardiac-digital-twin/blob/main/mkdocs.yml).

---

## Versions tested

| Component | Version |
|---|---|
| MATLAB | R2025a, R2026a |
| Simulink | bundled with the MATLAB versions above |
| Simulink Test | required for Gherkin verification |
| Simulink Requirements Toolbox | required for the `.slreqx` artifact |
| Simulink Agentic Toolkit | [latest release](https://github.com/matlab/simulink-agentic-toolkit/releases/latest) |
| GitHub Copilot | Agent mode + MCP enabled |
| VS Code | latest stable (or Insiders) |
| MkDocs Material | 9.5 or newer |
