%% startup.m
% MATLAB session initializer for the Cardiac Digital Twin demo.
% Run this ONCE at the start of each MATLAB session, then restart
% your Copilot session so the MCP server picks up the live MATLAB connection.
%
% Usage (from MATLAB command window):
%   cd('<repo-root>')
%   run('setup/startup.m')
%

fprintf('═══════════════════════════════════════════════════════\n');
fprintf('  Cardiac Digital Twin — Session Startup\n');
fprintf('═══════════════════════════════════════════════════════\n');

%% 1. Add model directory to path ─────────────────────────────────────────
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'model'));
addpath(fullfile(repoRoot, 'validation'));
fprintf('[1/4] Paths added: model, validation\n');

%% 2. Load cardiac parameters into base workspace ──────────────────────────
run(fullfile(repoRoot, 'model', 'cardiac_params.m'));
fprintf('[2/4] Cardiac parameters loaded\n');

%% 3. Initialize the Simulink Agentic Toolkit (MCP bridge) ─────────────────
% Requires prior toolkit installation:
%   setupAgenticToolkit("install")  [run once, outside this script]
toolkitPath = fullfile(userpath, '..', '.matlab', 'agentic-toolkits', 'simulink');
if exist(toolkitPath, 'dir')
    addpath(toolkitPath);
    try
        satk_initialize;
        fprintf('[3/4] Simulink Agentic Toolkit initialized (MCP bridge active)\n');
    catch ME
        fprintf('[3/4] WARNING: satk_initialize failed — %s\n', ME.message);
        fprintf('      Ensure toolkit is installed: setupAgenticToolkit("install")\n');
    end
else
    fprintf('[3/4] WARNING: Simulink Agentic Toolkit not found at expected path.\n');
    fprintf('      Install with: setupAgenticToolkit("install")\n');
end

%% 4. Build or reload the model ────────────────────────────────────────────
mdlFile = fullfile(repoRoot, 'model', 'CardiacDigitalTwin.slx');
if ~exist(mdlFile, 'file')
    fprintf('[4/4] Model not found — building CardiacDigitalTwin.slx ...\n');
    run(fullfile(repoRoot, 'model', 'create_cardiac_model.m'));
else
    fprintf('[4/4] Model found — opening CardiacDigitalTwin.slx\n');
    load_system(mdlFile);
    open_system(mdlFile);
end

%% ── Summary ──────────────────────────────────────────────────────────────
fprintf('\n═══════════════════════════════════════════════════════\n');
fprintf('  Startup complete.\n');
fprintf('  NEXT STEPS:\n');
fprintf('    1. Restart your Copilot / VS Code session\n');
fprintf('       so the MCP server connects to this MATLAB session.\n');
fprintf('    2. Open demo/live_prompts.md and start the demo.\n');
fprintf('═══════════════════════════════════════════════════════\n');
