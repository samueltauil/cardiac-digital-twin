%% linearize_baroreflex.m
% Phase 2 prompt 10 follow-on: linearize the closed-loop v2 model and
% inspect the baroreflex's effect on stability.
%
% We compute two linearizations:
%
%   1. Open-loop  - baroreflex disconnected, gain set to 0.
%   2. Closed-loop - baroreflex active at the nominal gain.
%
% Then we plot the Bode magnitude/phase and print the closed-loop poles.
% The point is to show that the autonomic loop adds a slow stable pole
% and shifts the bandwidth without destabilising the system.
%
% Requires:
%   - Simulink Control Design (for linearize)
%   - cardiac_params_v2.m loaded
%   - CardiacDigitalTwin_v2.slx built

if ~license('test', 'Simulink_Control_Design')
    warning('linearize_baroreflex:noSCD', ...
        'Simulink Control Design is not available; skipping.');
    return;
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'model'));

run(fullfile(repoRoot, 'model', 'cardiac_params_v2.m'));

mdl     = 'CardiacDigitalTwin_v2';
mdlFile = fullfile(repoRoot, 'model', [mdl '.slx']);
if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end

%% ── Linearization input/output points ─────────────────────────────────
% Linearize from BetaBlockerDose output (system input) to HeartRateModel
% output (system output).
io = [ ...
    linio([mdl '/BetaBlockerDose'],  1, 'input'); ...
    linio([mdl '/HeartRateModel'],   1, 'output') ...
];

% Snapshot the steady-state operating point at t = 3600 s. linearize
% must use this op point because the Hill equation u^n is undefined
% for u < 0, and the default t=0 op point gives spurious warnings and
% zero DC gain.
fprintf('Snapshotting steady-state operating point at t = 3600 s ...\n');
opPoint = findop(mdl, 3600);

%% ── Closed loop (nominal) ─────────────────────────────────────────────
fprintf('Linearizing closed-loop v2 (baroreflex active) ...\n');
sys_closed = linearize(mdl, opPoint, io);

%% ── Open loop (baroreflex disconnected) ───────────────────────────────
prevGain = baroreflex_gain;
assignin('base', 'baroreflex_gain', 0);
cleaner  = onCleanup(@() assignin('base', 'baroreflex_gain', prevGain));

% Re-snapshot the operating point with the baroreflex disabled, since
% the steady state shifts when the loop is opened.
opPointOpen = findop(mdl, 3600);
fprintf('Linearizing open-loop v2 (baroreflex disabled) ...\n');
sys_open = linearize(mdl, opPointOpen, io);

clear cleaner   % restore the original gain immediately

%% ── Report ───────────────────────────────────────────────────────────
p_open   = pole(sys_open);
p_closed = pole(sys_closed);

fprintf('\n=========================================================\n');
fprintf('  V2 LINEARIZATION SUMMARY\n');
fprintf('=========================================================\n');
fprintf('  Open-loop  DC gain  : %+.3f bpm/mg\n', dcgain(sys_open));
fprintf('  Closed-loop DC gain : %+.3f bpm/mg\n', dcgain(sys_closed));
fprintf('  Open-loop  poles    : %s\n', num2str(p_open(:).', '%+0.4f '));
fprintf('  Closed-loop poles   : %s\n', num2str(p_closed(:).', '%+0.4f '));
all_stable = all(real(p_closed) < 0);
fprintf('  Closed-loop stable  : %s\n', string(all_stable));
fprintf('=========================================================\n\n');

%% ── Bode plot ────────────────────────────────────────────────────────
fig = figure('Name', 'v2 baroreflex: open vs closed loop', ...
    'Color', 'w', 'Position', [140 140 820 540]);
bode(sys_open, 'r--', sys_closed, 'b-');
legend({'Open loop (baroreflex off)', 'Closed loop (baroreflex on)'}, ...
    'Location', 'southwest');
grid on;
title('Baroreflex effect on dose-to-HR frequency response');
