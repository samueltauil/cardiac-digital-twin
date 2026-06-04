%% run_simulation.m
% Runs a baseline simulation and a +20% beta-blocker dose simulation,
% then plots a side-by-side comparison of the key cardiac metrics.
%
% Prerequisites:
%   - setup/startup.m has been run (params loaded, toolkit initialized)
%   - CardiacDigitalTwin.slx exists (create_cardiac_model.m has been run)
%
% Usage:
%   run('model/run_simulation.m')

%% Load parameters
run(fullfile(fileparts(mfilename('fullpath')), 'cardiac_params.m'));

mdl     = 'CardiacDigitalTwin';
mdlFile = fullfile(fileparts(mfilename('fullpath')), [mdl '.slx']);

if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end

%% ── Run 1: Baseline (50 mg) ──────────────────────────────────────────────
fprintf('\n-- Simulation 1 of 2: Baseline (dose = %g mg) --\n', beta_blocker_dose_mg);

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(beta_blocker_dose_mg));
simOut1 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');

t1   = simOut1.tout;
hr1  = simOut1.HR_out;
co1  = simOut1.CO_out;
map1 = simOut1.MAP_out;

ss1 = t1 > 0.9 * t1(end);   % final 10% = steady-state window
hr1_ss  = mean(hr1(ss1));
co1_ss  = mean(co1(ss1));
map1_ss = mean(map1(ss1));

%% ── Run 2: Modified dose (+20%) ──────────────────────────────────────────
modified_dose_mg = beta_blocker_dose_mg * 1.20;
fprintf('-- Simulation 2 of 2: Modified (+20%% dose = %g mg) --\n', modified_dose_mg);

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(modified_dose_mg));
simOut2 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');

t2   = simOut2.tout;
hr2  = simOut2.HR_out;
co2  = simOut2.CO_out;
map2 = simOut2.MAP_out;

ss2 = t2 > 0.9 * t2(end);
hr2_ss  = mean(hr2(ss2));
co2_ss  = mean(co2(ss2));
map2_ss = mean(map2(ss2));

% Restore original dose so the model is ready for the next demo run
set_param([mdl '/BetaBlockerDose'], 'Value', num2str(beta_blocker_dose_mg));

%% ── Results table ────────────────────────────────────────────────────────
fprintf('\n==========================================================\n');
fprintf('  CARDIAC DIGITAL TWIN -- SIMULATION RESULTS\n');
fprintf('==========================================================\n');
fprintf('  Metric               Baseline (%gmg)  Modified (%gmg)  Delta\n', ...
    beta_blocker_dose_mg, modified_dose_mg);
fprintf('  --------------------------------------------------------\n');
fprintf('  Heart Rate (bpm)     %-16.1f %-16.1f %+.1f (%.1f%%)\n', ...
    hr1_ss, hr2_ss, hr2_ss-hr1_ss, (hr2_ss-hr1_ss)/hr1_ss*100);
fprintf('  Cardiac Output(L/m)  %-16.2f %-16.2f %+.2f (%.1f%%)\n', ...
    co1_ss, co2_ss, co2_ss-co1_ss, (co2_ss-co1_ss)/co1_ss*100);
fprintf('  Mean Art. P. (mmHg)  %-16.1f %-16.1f %+.1f (%.1f%%)\n', ...
    map1_ss, map2_ss, map2_ss-map1_ss, (map2_ss-map1_ss)/map1_ss*100);
fprintf('==========================================================\n\n');

%% ── Comparison plots ─────────────────────────────────────────────────────
t_min1 = t1 / 60;
t_min2 = t2 / 60;

figure('Name', 'Cardiac Digital Twin -- Beta-Blocker Dose Comparison', ...
    'Position', [100 100 1100 750]);

subplot(3,1,1);
plot(t_min1, hr1, 'b-',  'LineWidth', 2, ...
    'DisplayName', sprintf('Baseline (%g mg)', beta_blocker_dose_mg));
hold on;
plot(t_min2, hr2, 'r--', 'LineWidth', 2, ...
    'DisplayName', sprintf('+20%% dose (%g mg)', modified_dose_mg));
yline(hr1_ss, 'b:', 'LineWidth', 1);
yline(hr2_ss, 'r:', 'LineWidth', 1);
ylabel('Heart Rate (bpm)'); title('Heart Rate Response');
legend('Location', 'best'); grid on;

subplot(3,1,2);
plot(t_min1, co1, 'b-',  'LineWidth', 2);
hold on;
plot(t_min2, co2, 'r--', 'LineWidth', 2);
yline(co1_ss, 'b:', 'LineWidth', 1);
yline(co2_ss, 'r:', 'LineWidth', 1);
ylabel('Cardiac Output (L/min)'); title('Cardiac Output Response'); grid on;

subplot(3,1,3);
plot(t_min1, map1, 'b-',  'LineWidth', 2);
hold on;
plot(t_min2, map2, 'r--', 'LineWidth', 2);
yline(map1_ss, 'b:', 'LineWidth', 1);
yline(map2_ss, 'r:', 'LineWidth', 1);
ylabel('MAP (mmHg)'); xlabel('Time (minutes)');
title('Mean Arterial Pressure Response'); grid on;

sgtitle(sprintf('Effect of Beta-Blocker Dose Increase: %g mg to %g mg (+20%%)', ...
    beta_blocker_dose_mg, modified_dose_mg), 'FontSize', 13, 'FontWeight', 'bold');
