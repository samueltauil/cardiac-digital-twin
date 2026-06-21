# Cardiac Digital Twin: GitHub Copilot + Simulink Agentic Toolkit demo

## Why this matters

A pharmaceutical company developing a cardiovascular drug today asks:
> *"How will the average patient respond?"*

Patients aren't average, though. They differ in age, weight, kidney function, genetics, existing conditions, and current medications. A single clinical trial against an "average" captures none of that variability, and failed trials can cost **billions of dollars and years of time**.

A **cardiac digital twin** changes the question to:
> *"How will **this type** of patient respond?"*

By simulating the cardiovascular system computationally, researchers can explore dosage effects across patient profiles **before enrolling a single person**. The result is fewer failed trials, shorter timelines, and lower cost for personalized medicine.

---

## What this demo shows

This demo makes that idea concrete. It uses **GitHub Copilot** orchestrating the **Simulink Agentic Toolkit** via MCP to simulate a beta-blocker dosage change on a cardiac digital twin, entirely through natural-language prompts, with no manual code editing.

**Detailed documentation:** see the [MkDocs site](docs/index.md) for full implementation details, formulas, architecture, validation methodology, and the Copilot workflow narrative.

---

## Demo scenario

> *"Simulate the effect of increasing a patient's beta-blocker (metoprolol) dosage by 20%."*

In eight Copilot prompts, the AI assistant will:
1. Describe the cardiac Simulink model architecture
2. Locate and resolve the `beta_blocker_dose_mg` parameter
3. Apply the +20 % change (50 mg to 60 mg)
4. Re-run the simulation and compare the headline metrics
5. Interpret the physiological impact in clinical context
6. Generate a Gherkin verification test
7. Draft formal engineering requirements from the simulation results
8. Launch a real-time `uifigure` dashboard with overlaid run comparison

---

## Expected simulation results

| Metric | Baseline (50 mg) | Modified (60 mg) | Change |
|--------|:---:|:---:|:---:|
| Heart rate | 63.0 bpm | 60.6 bpm | -3.8 % |
| Cardiac output | 4.41 L/min | 4.24 L/min | -3.9 % |
| Mean arterial pressure | 79.4 mmHg | 76.3 mmHg | -3.9 % |

---

## Repository structure

```
cardiac-digital-twin/
|-- context.md                      Use-case analysis and toolkit capability baseline
|-- README.md                       This file
|-- .github/
|   |-- copilot-instructions.md     Repo-wide always-on context for every Copilot interaction
|   |-- agents/
|   |   `-- cardiac-demo.agent.md   Custom Copilot agent for the cardiac demo workflow
|   |-- instructions/
|   |   `-- matlab.instructions.md  MATLAB-specific coding conventions (applied to *.m files)
|   `-- prompts/
|       |-- 01-explore-model.prompt.md
|       |-- 02-find-dosage-parameter.prompt.md
|       |-- 03-apply-dose-change.prompt.md
|       |-- 04-run-simulation.prompt.md
|       |-- 05-interpret-clinical-impact.prompt.md
|       |-- 06-generate-validation-test.prompt.md
|       |-- 07-generate-requirements.prompt.md
|       `-- 08-realtime-dashboard.prompt.md
|-- .vscode/
|   `-- mcp.json                    Workspace MCP server config (Windows template)
|-- mkdocs.yml                      MkDocs site configuration
|-- docs/                           MkDocs source (Material theme, MathJax, Mermaid)
|-- model/
|   |-- cardiac_params.m            Workspace parameters loaded before simulation
|   |-- create_cardiac_model.m      Builds CardiacDigitalTwin.slx programmatically
|   `-- run_simulation.m            Runs baseline + modified scenario, plots comparison
|-- setup/
|   |-- startup.m                   MATLAB session initializer (run once per session)
|   |-- mcp-configuration.md        Full MCP setup guide (all platforms)
|   `-- preflight_checklist.md      Pre-demo verification checklist
|-- demo/
|   |-- live_prompts.md             8-step Copilot prompt sequence with timing and expected outputs
|   |-- scripted_runbook.md         Pre-verified fallback outputs for each step
|   |-- narrative_script.md         Executive narration track between prompts
|   `-- realtime_dashboard.m        Live uifigure dashboard (gauges + overlaid comparison)
|-- CardiacDigitalTwin_Requirements.slreqx  Formal engineering requirements artifact
`-- validation/
    |-- beta_blocker_dose_response.feature   Gherkin verification test
    |-- validation_criteria.md      10 pass/fail acceptance criteria with requirements traceability
    `-- validate_beta_blocker.m     Automated MATLAB validation suite
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| MATLAB R2023a or later | Must include Simulink. |
| Simulink Test | Optional. Needed only for the `model_test` MCP tool. |
| Simulink Agentic Toolkit | Latest release from [matlab/simulink-agentic-toolkit](https://github.com/matlab/simulink-agentic-toolkit). |
| GitHub Copilot | VS Code with Agent mode and MCP enabled. |

---

## Quick start

### Step 1. Install and configure the Simulink Agentic Toolkit

Download `agenticToolkitInstaller.mltbx` from the [latest release](https://github.com/matlab/simulink-agentic-toolkit/releases/latest), install it in MATLAB, then run:

```matlab
setupAgenticToolkit("install")
```

When prompted, select **GitHub Copilot** as the target agent. This installs the MCP server binary, registers Simulink skills, and writes a global VS Code MCP configuration.

See [`setup/mcp-configuration.md`](setup/mcp-configuration.md) for the full setup guide including manual configuration, macOS and Linux paths, and troubleshooting.

### Step 2. Configure the workspace MCP server

This repo ships `.vscode/mcp.json` pre-configured for Windows. After the automated install, no edits are needed on Windows. For macOS or Linux, replace the paths in `.vscode/mcp.json` with the platform-specific variants documented in [`setup/mcp-configuration.md`](setup/mcp-configuration.md).

> **Copilot CLI users:** The CLI stores MCP config in `~/.copilot/mcp-config.json`. Run `/mcp add` in interactive mode, or edit the file directly using the format in [`setup/mcp-configuration.md`](setup/mcp-configuration.md#copilot-cli).

Reload VS Code after any MCP configuration change: `Cmd/Ctrl+Shift+P`, then `Developer: Reload Window`.

### Step 3. Initialize MATLAB and build the model

Open MATLAB, navigate to this repo, and run the startup script:

```matlab
cd('<repo-root>')
run('setup/startup.m')
```

This loads workspace parameters, initializes the Simulink Agentic Toolkit (which shares the MATLAB session with the MCP server), and opens or builds `CardiacDigitalTwin.slx`.

After `startup.m` completes, **reload VS Code** so Copilot's MCP client attaches to the newly shared MATLAB session.

### Step 4. Verify the MCP connection

Ask Copilot in Agent mode:

```
Describe the structure of the currently open Simulink model.
```

Copilot should call `model_overview` and return a description of the `CardiacDigitalTwin` subsystem hierarchy. If it responds without calling MCP tools, see the troubleshooting section in [`setup/mcp-configuration.md`](setup/mcp-configuration.md).

### Step 5. Run the demo

Follow the files in `demo/` in order:

| File | Purpose |
|------|---------|
| `demo/live_prompts.md` | 8-prompt live Copilot walkthrough with expected outputs and timing. |
| `demo/scripted_runbook.md` | Pre-verified fallback outputs if live execution fails. |
| `demo/narrative_script.md` | Executive narration to speak between technical steps. |
| `demo/realtime_dashboard.m` | Live `uifigure` dashboard with overlaid run comparison (Prompt 8). |

Before every session, complete all checks in `setup/preflight_checklist.md`.

---

## Documentation site

The full implementation reference (model architecture, formulas, validation methodology, requirements artifact, real-time dashboard, and the Copilot prompt narrative) is published as a [MkDocs](https://www.mkdocs.org/) site under [`docs/`](docs/index.md), themed with [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

### Build and preview locally

```bash
# 1. Install build dependencies (one-time)
pip install -r docs-requirements.txt

# 2. Live-reload preview at http://127.0.0.1:8000
mkdocs serve

# 3. Produce a static site in ./site/
mkdocs build
```

### Page map

| Page | Content |
|------|---------|
| [Home](docs/index.md) | Vision, value, and what Copilot adds on top of the model. |
| [The Copilot workflow](docs/copilot-workflow.md) | Prompt-by-prompt narrative, the core of the demo. |
| [Model architecture](docs/architecture.md) | Subsystem topology, block-level internals, build-script rationale. |
| [Physiology and math](docs/physiology.md) | All four formulas with derivations and clinical references. |
| [Validation](docs/validation.md) | The Gherkin test, the MATLAB suite, and when to use each. |
| [Requirements](docs/requirements.md) | EARS-pattern requirements, link set, and the REQ_CDT_003 verification gap. |
| [Real-time dashboard](docs/dashboard.md) | Pacing, `RuntimeObject` polling, and troubleshooting. |
| [Reference](docs/reference.md) | Parameters, MCP tools, and file map. |

The built output (`./site/`) is gitignored. To publish to GitHub Pages, run `mkdocs gh-deploy` from a branch with push access; it publishes to the `gh-pages` branch.

---

## Demo flow summary

```
[Prompt 1] Describe model structure       -- model_overview, model_read
[Prompt 2] Find dosage parameter          -- model_query_params, model_resolve_params
[Prompt 3] Apply +20% dose change         -- model_edit / assignin
[Prompt 4] Run simulation and compare     -- sim, Simulink.SimulationInput
[Prompt 5] Explain physiological impact   -- Copilot reasoning + specifying-plant-models skill
[Prompt 6] Generate verification test     -- model_test (Gherkin)
[Prompt 7] Draft engineering requirements -- generate-requirement-drafts skill (slreq)
[Prompt 8] Real-time dashboard            -- realtime_dashboard.m (uifigure + pacing)
```

---

## References

- [Simulink Agentic Toolkit](https://github.com/matlab/simulink-agentic-toolkit)
- [Simulink Agentic Toolkit, getting started guide](https://github.com/matlab/simulink-agentic-toolkit/blob/main/GETTING_STARTED.md)
- [MATLAB MCP Core Server](https://github.com/matlab/matlab-mcp-core-server)
- [MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
