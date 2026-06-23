%% validate_beta_blocker.m
% Runs both simulation scenarios and checks all validation criteria
% defined in validation/validation_criteria.md.
%
% Prerequisites:
%   - setup/startup.m has been run
%   - CardiacDigitalTwin.slx exists and is loaded
%
% Output: PASSED / FAILED summary for each of the 10 criteria (V1–V10).
%

%% ── Setup ────────────────────────────────────────────────────────────────
run(fullfile(fileparts(mfilename('fullpath')), '..', 'model', 'cardiac_params.m'));

mdl     = 'CardiacDigitalTwin';
mdlFile = fullfile(fileparts(mfilename('fullpath')), '..', 'model', [mdl '.slx']);

if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end

results = struct();  % accumulates pass/fail for each criterion

fprintf('\n═══════════════════════════════════════════════════════════════\n');
fprintf('  CARDIAC DIGITAL TWIN — VALIDATION SUITE\n');
fprintf('  Scenario: beta_blocker_dose_mg 50 mg → 60 mg (+20%%)\n');
fprintf('═══════════════════════════════════════════════════════════════\n');

%% ── Simulation 1: Baseline (50 mg) ──────────────────────────────────────
baseline_dose = 50;
modified_dose = 60;

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(baseline_dose));
simOut1 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
t1   = simOut1.tout;
hr1  = simOut1.HR_out;
co1  = simOut1.CO_out;
map1 = simOut1.MAP_out;

ss1 = t1 > 0.9 * t1(end);
hr1_ss  = mean(hr1(ss1));
hr1_min = min(hr1(ss1));
co1_ss  = mean(co1(ss1));
co1_min = min(co1(ss1));
map1_ss = mean(map1(ss1));

%% ── Simulation 2: Modified (60 mg) ──────────────────────────────────────

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(modified_dose));
simOut2 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
t2   = simOut2.tout;
hr2  = simOut2.HR_out;
co2  = simOut2.CO_out;
map2 = simOut2.MAP_out;

ss2 = t2 > 0.9 * t2(end);
hr2_ss  = mean(hr2(ss2));
hr2_min = min(hr2(ss2));
co2_ss  = mean(co2(ss2));
co2_min = min(co2(ss2));
map2_ss = mean(map2(ss2));

% Restore original dose
set_param([mdl '/BetaBlockerDose'], 'Value', num2str(beta_blocker_dose_mg));
%% ── Validation checks ────────────────────────────────────────────────────
fprintf('\n── Baseline Accuracy (50 mg) ───────────────────────────────────\n');

% V1: Baseline HR
v1 = hr1_ss >= 66.0 && hr1_ss <= 69.0;
printResult('V1', 'Baseline HR within 67.5 ± 1.5 bpm', v1, ...
    sprintf('%.1f bpm', hr1_ss), '66.0-69.0 bpm');

% V2: Baseline CO
v2 = co1_ss >= 4.62 && co1_ss <= 4.82;
printResult('V2', 'Baseline CO within 4.72 ± 0.10 L/min', v2, ...
    sprintf('%.2f L/min', co1_ss), '4.62-4.82 L/min');

% V3: Baseline MAP
v3 = map1_ss >= 82.4 && map1_ss <= 87.4;
printResult('V3', 'Baseline MAP within 84.9 ± 2.5 mmHg', v3, ...
    sprintf('%.1f mmHg', map1_ss), '82.4-87.4 mmHg');

fprintf('\n── Directional Response (50 mg → 60 mg) ───────────────────────\n');

% V4: HR decreases
v4 = hr2_ss < hr1_ss;
printResult('V4', 'HR decreases with increased dose', v4, ...
    sprintf('%.1f < %.1f bpm', hr2_ss, hr1_ss), 'HR_60 < HR_50');

% V5: CO decreases
v5 = co2_ss < co1_ss;
printResult('V5', 'CO decreases with increased dose', v5, ...
    sprintf('%.2f < %.2f L/min', co2_ss, co1_ss), 'CO_60 < CO_50');

% V6: MAP decreases
v6 = map2_ss < map1_ss;
printResult('V6', 'MAP decreases with increased dose', v6, ...
    sprintf('%.1f < %.1f mmHg', map2_ss, map1_ss), 'MAP_60 < MAP_50');

% V7: HR delta >= 0.5 bpm. The marginal drop is small because the Hill
% curve saturates near Emax and the baroreflex partially compensates.
deltaHR = hr1_ss - hr2_ss;  % positive = reduction
v7 = deltaHR >= 0.5;
printResult('V7', 'HR reduction >= 0.5 bpm', v7, ...
    sprintf('DeltaHR = -%.1f bpm', deltaHR), 'DeltaHR >= 0.5 bpm');

fprintf('\n── Safety Bounds ───────────────────────────────────────────────\n');

% V8: HR never below 40 bpm
v8 = hr2_min > 40;
printResult('V8', 'Heart rate stays above 40 bpm', v8, ...
    sprintf('min HR = %.1f bpm', hr2_min), '> 40 bpm');

% V9: CO never below 3.0 L/min
v9 = co2_min > 3.0;
printResult('V9', 'Cardiac output stays above 3.0 L/min', v9, ...
    sprintf('min CO = %.2f L/min', co2_min), '> 3.0 L/min');

fprintf('\n── Convergence ─────────────────────────────────────────────────\n');

% V10: Steady-state convergence (std < 0.1% of mean over final 10%)
hr_ss_std_pct = std(hr2(ss2)) / mean(hr2(ss2)) * 100;
v10 = hr_ss_std_pct < 0.1;
printResult('V10', 'Simulation converges to steady state', v10, ...
    sprintf('SS variance = %.4f%%', hr_ss_std_pct), '< 0.1%%');

%% ── Final verdict ────────────────────────────────────────────────────────
allPassed = v1 && v2 && v3 && v4 && v5 && v6 && v7 && v8 && v9 && v10;
nPassed   = sum([v1, v2, v3, v4, v5, v6, v7, v8, v9, v10]);

fprintf('\n═══════════════════════════════════════════════════════════════\n');
if allPassed
    fprintf('  ALL CRITERIA PASSED (%d/10) -- Demo scenario validated.\n', nPassed);
else
    fprintf('  %d/10 CRITERIA PASSED -- Review failing checks above.\n', nPassed);
end
fprintf('═══════════════════════════════════════════════════════════════\n\n');

%% ════════════════════════════════════════════════════════════════════════
%% LOCAL FUNCTIONS (must be at end of script)
%% ════════════════════════════════════════════════════════════════════════

function printResult(id, description, passed, actual, expected)
% Prints a single validation result line with PASS/FAIL status.
    status = 'PASS';
    if ~passed, status = 'FAIL'; end
    fprintf('  [%s] %s -- %s\n', status, id, description);
    fprintf('       Actual: %s   Expected: %s\n', actual, expected);
end
