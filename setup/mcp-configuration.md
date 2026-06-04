# MCP Configuration — Simulink Agentic Toolkit + GitHub Copilot

This guide walks through every step to configure the MATLAB MCP server so  
GitHub Copilot can call Simulink tools (`model_overview`, `model_read`,  
`model_edit`, `model_test`, `model_query_params`, `model_resolve_params`,  
`model_check`) on the open `CardiacDigitalTwin` model.

---

## Overview

The connection between Copilot and MATLAB/Simulink involves three layers:

```
GitHub Copilot (VS Code)
       │  MCP (stdio)
       ▼
MATLAB MCP Core Server   ←── .vscode/mcp.json tells VS Code where to find it
       │  MATLAB Connector
       ▼
Running MATLAB session   ←── satk_initialize shares the session
       │  Simulink Agentic Toolkit
       ▼
CardiacDigitalTwin.slx
```

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

The wizard will:
1. Download the MCP server binary to `~/.matlab/agentic-toolkits/bin/`
2. Install MATLAB-side MCP components (`--setup-matlab`)
3. Ask which agent to configure — **select "GitHub Copilot"**
4. Write MCP configuration to the VS Code user profile `mcp.json`
5. Create skill symlinks in `~/.agents/skills/`

> **After setup completes:** restart MATLAB, then reload VS Code  
> (`Ctrl+Shift+P` → `Developer: Reload Window`).

---

## Step 3 — Configure MCP for This Project (Workspace-Level)

The automated setup writes a **global** user-level config. This repo also  
ships a **workspace-level** `.vscode/mcp.json` template that takes precedence  
for this project and can be committed to share the configuration with your team.

### Windows (default after automated install)

The template at `.vscode/mcp.json` uses `${env:USERPROFILE}` to resolve  
the install path automatically — no edits needed if you used automated setup.

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

### macOS (Apple Silicon)

Replace `.vscode/mcp.json` contents with:

```json
{
    "servers": {
        "matlab-simulink": {
            "type": "stdio",
            "command": "${env:HOME}/.matlab/agentic-toolkits/bin/matlab-mcp-core-server",
            "args": [
                "--matlab-session-mode=existing",
                "--extension-file=${env:HOME}/.matlab/agentic-toolkits/simulink/tools/tools.json"
            ]
        }
    }
}
```

### Linux

Same as macOS above — `${env:HOME}` resolves to your home directory.

### Manual install (custom binary path)

If you installed the MCP server binary to a non-default location, replace  
the `command` value with the full absolute path to your binary:

```json
{
    "servers": {
        "matlab-simulink": {
            "type": "stdio",
            "command": "C:\\Tools\\matlab-mcp-core-server.exe",
            "args": [
                "--matlab-session-mode=existing",
                "--extension-file=C:\\Tools\\simulink-agentic-toolkit\\tools\\tools.json"
            ]
        }
    }
}
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
1. Calls `shareMATLABSession` so the MCP server can attach
2. Adds the Simulink Agentic Toolkit to the MATLAB path
3. Runs `validate_installation` to confirm everything is connected

After running `startup.m`, **reload your VS Code window** so Copilot's  
MCP client reconnects to the newly shared MATLAB session.

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
| Copilot doesn't call any Simulink tools | MCP server not configured or not running | Check `.vscode/mcp.json` path is correct; reload VS Code |
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

`Ctrl+Shift+P` → `MCP: List Servers` — confirm `matlab-simulink` shows as running.

---

## Copilot CLI

For **GitHub Copilot CLI** (`copilot` command), MCP servers are configured in
`~/.copilot/mcp-config.json` — not in `.vscode/mcp.json`.

Use the interactive command to add the server:

```
/mcp add
```

Or edit `~/.copilot/mcp-config.json` directly:

```json
{
  "mcpServers": {
    "matlab-simulink": {
      "type": "stdio",
      "command": "<path-to>/matlab-mcp-core-server",
      "args": [
        "--matlab-session-mode=existing",
        "--extension-file=<path-to>/simulink/tools/tools.json"
      ],
      "tools": ["*"]
    }
  }
}
```

Replace `<path-to>` with the actual install path from `setupAgenticToolkit("status")`.

---

## Skill Registration

Skills teach Copilot MBD best practices. The automated setup registers them  
via symlinks in `~/.agents/skills/`. Verify they are available by checking  
Copilot's skill list or asking:

```
What Simulink skills do you have available?
```

Expected skills: `building-simulink-models`, `simulating-simulink-models`,  
`testing-simulink-models`, `specifying-mbd-algorithms`, `specifying-plant-models`,  
`generate-requirement-drafts`, `filing-bug-reports`.

---

## References

- [Simulink Agentic Toolkit — Getting Started](https://github.com/matlab/simulink-agentic-toolkit/blob/main/GETTING_STARTED.md)
- [MATLAB MCP Core Server — GitHub](https://github.com/matlab/matlab-mcp-core-server)
- [MCP servers in VS Code — Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
