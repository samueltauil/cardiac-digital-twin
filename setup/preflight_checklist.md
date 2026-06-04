# Pre-Demo Preflight Checklist

Run this checklist **before every demo session** (ideally 15–30 minutes before).  
Mark each step ✅ before proceeding to the next.

---

## Environment Startup

| # | Step | Command / Action | Expected Result |
|---|------|-----------------|----------------|
| 1 | Open MATLAB | Launch MATLAB R2023a+ | MATLAB desktop opens |
| 2 | Navigate to repo | `cd '<repo-root>'` | Working directory is correct |
| 3 | Run startup script | `run('setup/startup.m')` | All 4 steps show success; no errors |
| 4 | Verify model open | Check MATLAB model window | `CardiacDigitalTwin.slx` is open |
| 5 | Check parameters | `whos beta_blocker_dose_mg` | Value is `50` |

---

## MCP Configuration Verification

| # | Step | Command / Action | Expected Result |
|---|------|-----------------|----------------|
| 6 | Verify `.vscode/mcp.json` | Open `.vscode/mcp.json` in VS Code | File exists; `--extension-file` path points to an installed `tools.json` |
| 7 | Check MCP server status | `Ctrl+Shift+P` → `MCP: List Servers` | `simulink-agentic-toolkit` is listed and **running** |
| 8 | Reload VS Code after MATLAB init | `Ctrl+Shift+P` → `Developer: Reload Window` | VS Code reloads; MCP server reattaches to MATLAB session |

---

## MCP Bridge Verification

| # | Step | Command / Action | Expected Result |
|---|------|-----------------|----------------|
| 9 | Test MCP connectivity | Ask Copilot: `"Describe the currently open Simulink model."` | Copilot calls `model_overview` and returns a description of `CardiacDigitalTwin` |
| 10 | Test parameter query | Ask Copilot: `"What is the current value of beta_blocker_dose_mg?"` | Returns `50` mg |

---

## Simulation Dry Run

| # | Step | Command / Action | Expected Result |
|---|------|-----------------|----------------|
| 11 | Run baseline simulation | `run('model/run_simulation.m')` | Results table prints; plot appears |
| 12 | Verify baseline values | Check MATLAB output | HR ≈ 63 bpm, CO ≈ 4.41 L/min, MAP ≈ 79 mmHg |
| 13 | Close figure | `close all` | Clean workspace for demo |
| 14 | Reset dose | `set_param('CardiacDigitalTwin/BetaBlockerDose', 'Value', '50')` | Confirmed in model |

---

## Copilot Session Check

| # | Step | Command / Action | Expected Result |
|---|------|-----------------|----------------|
| 15 | Confirm agent mode | VS Code Copilot → Agent tab active | Agent mode enabled |
| 16 | Confirm MCP tools | `Ctrl+Shift+P` → `MCP: List Servers` | All Simulink tools listed as available |
| 17 | Open demo prompts | `demo/live_prompts.md` open in editor | Ready to copy-paste |
| 18 | Open fallback runbook | `demo/scripted_runbook.md` open in split pane | Fallback ready |

---

## Known Recovery Commands

| Problem | Recovery Action |
|---------|----------------|
| MATLAB session lost | Re-run `setup/startup.m`; restart VS Code |
| Model not responding | `close_system('CardiacDigitalTwin', 0); run('setup/startup.m')` |
| Wrong parameter value | `beta_blocker_dose_mg = 50; set_param('CardiacDigitalTwin/BetaBlockerDose', 'Value', '50')` |
| Copilot can't find model | Ensure model is *open* (not just loaded): `open_system('CardiacDigitalTwin')` |
| Simulation timeout | Reduce stop time: `set_param('CardiacDigitalTwin', 'StopTime', '600')` |
| MCP tools not appearing | Reload VS Code window (`Ctrl+Shift+P` → `Developer: Reload Window`) |

---

## Day-of-Demo Timeline

| Time Before Demo | Action |
|-----------------|--------|
| T−30 min | Run full preflight; complete all 18 checks |
| T−15 min | Do one complete silent rehearsal (live path) |
| T−5 min | Reset model to baseline; close all figures |
| T−2 min | Confirm VS Code and MATLAB are visible on screen |
| T+0 | Start with **Prompt 1** from `live_prompts.md` |
| If live fails | Switch to `scripted_runbook.md` at any point |
