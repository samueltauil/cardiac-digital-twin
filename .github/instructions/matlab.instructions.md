---
applyTo: "**/*.m"
---

# MATLAB conventions for this repository

## Script structure

- Use `%%` section comments as section headers; keep them descriptive (e.g., `%% ── Run baseline simulation ──`)
- Use `%` for inline comments only when the line is non-obvious
- Group related parameters and computations under a single section header

## Local functions

Local functions **must appear at the end of the script file**, after all executable code.
This is a MATLAB language requirement for script files (as opposed to function files).

```matlab
% ... all executable code first ...

%% ════════════════════════════════════════════════════════════════════════
%% LOCAL FUNCTIONS
%% ════════════════════════════════════════════════════════════════════════

function result = myHelper(x)
    result = x * 2;
end
```

## Simulation output access

When using `sim()` with `ReturnWorkspaceOutputs='on'` and `To Workspace` blocks
with `SaveFormat='Array'`, access signals by **named field** — never by numeric index:

```matlab
% Correct
hr = simOut.HR_out;
co = simOut.CO_out;
map = simOut.MAP_out;

% Wrong — fragile and order-dependent
hr = simOut.yout{1}.Values.Data;
```

## Steady-state calculation

Steady state is the final 10% of the simulation time window:

```matlab
ss_idx = t > 0.9 * t(end);
ss_mean = mean(signal(ss_idx));
```

## Parameter loading

Always check if parameters are already loaded before running `cardiac_params.m`:

```matlab
if ~exist('beta_blocker_dose_mg', 'var')
    run(fullfile(fileparts(mfilename('fullpath')), 'cardiac_params.m'));
end
```

## Model loading

Check if the model is already loaded before calling `load_system`:

```matlab
if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end
```

## Restore state after changes

Always restore the original parameter value after running modified simulations
so the model is ready for the next demo run:

```matlab
set_param([mdl '/BetaBlockerDose'], 'Value', num2str(beta_blocker_dose_mg));
```
