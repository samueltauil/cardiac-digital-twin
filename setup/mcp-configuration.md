# MCP Configuration — Simulink Agentic Toolkit + GitHub Copilot

This guide walks through every step to configure the MATLAB MCP server so  
GitHub Copilot can call Simulink tools (`model_overview`, `model_read`,  
`model_edit`, `model_test`, `model_query_params`, `model_resolve_params`,  
`model_check`) on the open `CardiacDigitalTwin` model.

---

## Overview

The connection between Copilot and MATLAB/Simulink involves three layers:

```
GitHub Copilot (VS Code or Copilot CLI)
       │  MCP (stdio)
       ▼
MATLAB MCP Core Server   ←── .github/mcp.json   (Copilot CLI; repo-level)
                         ←── .vscode/mcp.json   (VS Code workspace)
       │  MATLAB Connector
       ▼
Running MATLAB session   ←── satk_initialize shares the session
       │  Simulink Agentic Toolkit
       ▼
CardiacDigitalTwin.slx
```

This repo ships **both** files so the same MCP server is picked up whether you
run Copilot inside VS Code or via the `copilot` CLI. They reference the same
binary; only the JSON root key differs (`servers` for VS Code, `mcpServers`
for the CLI).

---

## Step 1 — Install MATLAB and Simulink

- **MATLAB R2023a or later** with **Simulink** is required.
- Optional but recommended for the `model_test` tool: **Simulink Test**.
- Confirm MATLAB is on your system PATH:
  ```
  matlab -batch "disp(version)"
  ```

---

## Step 2 — Install the Simulink Agentic Toolkit

The automated installer handles the MCP server binary, MATLAB-side toolbox,  
and (optionally) writes the global VS Code MCP configuration.

### 2a. Download the installer

Download `agenticToolkitInstaller.mltbx` from the [latest GitHub release](https://github.com/matlab/simulink-agentic-toolkit/releases/latest).

### 2b. Install in MATLAB

Double-click the `.mltbx` file, or run:

```matlab
matlab.addons.toolbox.installToolbox("agenticToolkitInstaller.mltbx")
```

### 2c. Run automated setup

```matlab
setupAgenticToolkit("install")
```

The interactive wizard walks you through:
1. **Select toolkits** — choose MATLAB Agentic Toolkit, Simulink Agentic Toolkit, or both
2. **Download** — MCP server binary and toolkit files from GitHub releases go to `~/.matlab/agentic-toolkits/` (`%USERPROFILE%\.matlab\agentic-toolkits\` on Windows)
3. **Select agent** — choose from Claude Code, **GitHub Copilot**, Codex, Gemini CLI, or Amp
4. **Choose scope** — global (all projects) or project-level
5. **Enable toolkits** — select which installed toolkits to activate for this configuration

After the wizard, setup writes the MCP config to your agent's config file and creates skill symlinks in `~/.agents/skills/`.

> **After first install:** **restart MATLAB** so the newly installed MCP components are on the path. Then reload VS Code (`Cmd/Ctrl+Shift+P` → `Developer: Reload Window`).

**VS Code user-profile `mcp.json` location (written automatically by setup):**

| Platform | Path |
|----------|------|
| Windows  | `%APPDATA%\Code\User\mcp.json` |
| macOS    | `~/Library/Application Support/Code/User/mcp.json` |
| Linux    | `~/.config/Code/User/mcp.json` |

---

## Step 3 — Configure MCP for This Project (Repo-Level)

The automated setup writes a **global** user-level config. This repo also  
ships **repo-level** templates that take precedence for this project and  
can be committed to share the configuration with your team:

| File | Read by | Root JSON key |
|------|---------|---------------|
| `.github/mcp.json` | GitHub Copilot CLI (`copilot` command) | `mcpServers` |
| `.vscode/mcp.json` | VS Code (Copilot in Agent mode) | `servers` |

Both files describe the **same** `matlab-simulink` server. You only need to
edit the platform-specific paths once per file when switching OS.

> **Why two files?** Copilot CLI looks for `.mcp.json` or `.github/mcp.json`
> using the `mcpServers` schema (same as `~/.copilot/mcp-config.json`).
> VS Code only auto-discovers `.vscode/mcp.json` and uses the `servers`
> schema. Keeping both in sync gives every team member a working setup
> regardless of which Copilot surface they use.

### Windows (default after automated install)

The shipped templates use `${env:USERPROFILE}` to resolve the install path  
automatically — no edits needed if you used the automated setup.

**`.github/mcp.json`** (Copilot CLI):

```json
{
    "mcpServers": {
        "matlab-simulink": {
            "type": "stdio",
            "command": "${env:USERPROFILE}\\.matlab\\agentic-toolkits\\bin\\matlab-mcp-core-server.exe",
            "args": [
                "--matlab-session-mode=existing",
                "--extension-file=${env:USERPROFILE}\\.matlab\\agentic-toolkits\\simulink\\tools\\tools.json"
            ],
            "tools": ["*"]
        }
    }
}
```

**`.vscode/mcp.json`** (VS Code):

```json
{
    "servers": {
        "matlab-simulink": {
            "type": "stdio",
            "command": "${env:USERPROFILE}\\.matlab\\agentic-toolkits\\bin\\matlab-mcp-core-server.exe",
            "args": [
                "--matlab-session-mode=existing",
                "--extension-file=${env:USERPROFILE}\\.matlab\\agentic-toolkits\\simulink\\tools\\tools.json"
            ]
        }
    }
}
```

### macOS (Apple Silicon) / Linux

Replace the `command` and `--extension-file` paths in **both** files with:

- `command`: `${env:HOME}/.matlab/agentic-toolkits/bin/matlab-mcp-core-server`
- `--extension-file=${env:HOME}/.matlab/agentic-toolkits/simulink/tools/tools.json`

Keep the rest of each file unchanged (preserve `mcpServers` vs `servers`
at the root).

### Manual install (custom binary path)

If you installed the MCP server binary to a non-default location, replace  
the `command` value in both files with the full absolute path to your
binary, and the `--extension-file` argument with the absolute path to your
`tools.json`. For example:

```
"command": "C:\\Tools\\matlab-mcp-core-server.exe",
"args": [
    "--matlab-session-mode=existing",
    "--extension-file=C:\\Tools\\simulink-agentic-toolkit\\tools\\tools.json"
]
```

> **Key flags explained:**
> - `--matlab-session-mode=existing` — attaches to your running MATLAB session  
>   instead of launching a new one. Required so the toolkit can access  
>   `CardiacDigitalTwin.slx` which is already open.
> - `--extension-file` — points to the Simulink tool definitions JSON, which  
>   registers `model_edit`, `model_read`, and all other Simulink MCP tools  
>   with the server.

---

## Step 4 — Initialize MATLAB Each Session

Before starting a demo, run the startup script once per MATLAB session:

```matlab
cd('<repo-root>')
run('setup/startup.m')
```

This calls `satk_initialize`, which:
1. Adds the toolkit's tool directories to the MATLAB path
2. Calls `shareMATLABSession` so the MCP server can attach to this session
3. Runs `validate_installation` to confirm everything is connected

After running `startup.m`, **reload your VS Code window** (`Cmd/Ctrl+Shift+P` → `Developer: Reload Window`) so Copilot's MCP client reconnects to the newly shared MATLAB session.

> **Tip — automate per-session init:** Add the following to your MATLAB [`startup.m`](https://www.mathworks.com/help/matlab/ref/startup.html) to avoid running this manually each time:
> ```matlab
> % Initialize Simulink Agentic Toolkit (adjust version check as needed)
> if contains(version, 'R2026a') || contains(version, 'R2025a')
>     addpath("~/.matlab/agentic-toolkits/simulink")
>     satk_initialize
> end
> ```

---

## Step 5 — Verify the Connection

Ask Copilot in Agent mode:

```
Describe the structure of the currently open Simulink model.
```

**Expected:** Copilot calls `model_overview`, reads the `CardiacDigitalTwin`  
hierarchy, and returns a description of the four subsystems.

If Copilot responds without calling any MCP tools, see [Troubleshooting](#troubleshooting).

---

## Updating the Toolkit

```matlab
setupAgenticToolkit("update")
```

After updating: re-run `satk_initialize` in MATLAB and restart your Copilot session.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Copilot doesn't call any Simulink tools | MCP server not configured or not running | Check `.github/mcp.json` (Copilot CLI) or `.vscode/mcp.json` (VS Code) paths; reload the host |
| `model_overview` returns empty or errors | MATLAB session not shared | Run `satk_initialize` in MATLAB; reload VS Code |
| "Undefined function satk_initialize" | Toolkit path not added | Run `addpath("~/.matlab/agentic-toolkits/simulink")` then `satk_initialize` |
| MCP server binary not found | Installer wrote to different path | Run `setupAgenticToolkit("status")` to find actual path |
| macOS: binary blocked by Gatekeeper | Quarantine flag | `xattr -d com.apple.quarantine ~/.matlab/agentic-toolkits/bin/matlab-mcp-core-server` |
| Skills not appearing in Copilot | Symlinks not created | Re-run `setupAgenticToolkit("configure")` |
| Slow tool responses / timeouts | MATLAB operation latency | Pre-load model before demo (`open_system('CardiacDigitalTwin')`) |

### Verify toolkit status

```matlab
setupAgenticToolkit("status")
```

### Re-run configuration only (no re-install)

```matlab
setupAgenticToolkit("configure")
```

### Check server is reachable (VS Code)

`Cmd/Ctrl+Shift+P` → `MCP: List Servers` — confirm `matlab-simulink` shows as running.

---

## Copilot CLI

**GitHub Copilot CLI** (`copilot` command) reads MCP server configuration
from, in order of precedence:

1. `.mcp.json` (project root)
2. `.github/mcp.json` (repo-level — **shipped by this repo**)
3. `~/.copilot/mcp-config.json` (user-level)

Because `.github/mcp.json` is committed, anyone who clones the repo and runs
`copilot` from the repo root picks up the `matlab-simulink` server with no
extra setup beyond installing the MATLAB MCP Core Server binary.

To override or add servers per-user, edit `~/.copilot/mcp-config.json` or
use the interactive command inside `copilot`:

```
/mcp add
```

The user-level file uses the same `mcpServers` schema as `.github/mcp.json`.
Replace any `<path-to>` placeholders with the actual install path reported
by `setupAgenticToolkit("status")`.

---

## Skill Registration

**Skills are different from MCP tools.** MCP tools are programmatic actions Copilot
can *call* (e.g., `model_edit`). Skills are markdown guidance documents that teach
Copilot *how to reason* about specific Simulink workflows. Both work together:
skills guide the reasoning; tools execute the actions.

The automated setup symlinks skill files to `~/.agents/skills/`. They are
automatically available to any Copilot CLI agent that declares them.

### Skills installed by the toolkit

| Skill | What it teaches Copilot | Used in this demo |
|-------|------------------------|-------------------|
| `simulating-simulink-models` | How to set up, run, and compare simulations | Prompt 4 |
| `testing-simulink-models` | How to generate and interpret SLTest / Gherkin tests | Prompt 6 |
| `specifying-plant-models` | How to describe physical system models | Prompt 1 |
| `specifying-mbd-algorithms` | How to reason about model-based algorithm design | Prompt 2 |
| `building-simulink-models` | How to construct and navigate model hierarchies | Prompt 1 |
| `generate-requirement-drafts` | How to derive formal requirements from model behaviour | Prompt 7 |
| `filing-bug-reports` | How to write structured Simulink defect reports | Not used in demo |

### How skills are activated in the demo

The `cardiac-demo` custom agent (`.github/agents/cardiac-demo.agent.md`)
declares the relevant skills in its frontmatter. When you invoke the agent,
Copilot automatically loads the skill guidance alongside the MCP tools.

### Verify skills are registered

Ask Copilot:

```
What Simulink skills do you have available?
```

Or check that the symlinks exist:

```bash
# macOS / Linux
ls ~/.agents/skills/

# Windows (PowerShell)
Get-ChildItem "$env:USERPROFILE\.agents\skills\"
```

Expected entries: `building-simulink-models`, `simulating-simulink-models`,
`testing-simulink-models`, `specifying-mbd-algorithms`, `specifying-plant-models`,
`generate-requirement-drafts`, `filing-bug-reports`.

If skills are missing, re-run setup:

```matlab
setupAgenticToolkit("configure")
```

---

## References

- [Simulink Agentic Toolkit — Getting Started](https://github.com/matlab/simulink-agentic-toolkit/blob/main/GETTING_STARTED.md)
- [MATLAB MCP Core Server — GitHub](https://github.com/matlab/matlab-mcp-core-server)
- [MCP servers in VS Code — Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
