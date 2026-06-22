%% run_simulation_v2.m
% Runs the advanced (v2) cardiac digital twin at baseline and +20% dose,
% then prints a comparison table that mirrors run_simulation.m for v1.
% The interesting contrast is the saturation: v2's marginal HR drop at
% the higher dose is smaller than v1's, because the Hill curve is
% flattening as receptor binding approaches Emax.

%% Load v2 parameters and model
run(fullfile(fileparts(mfilename('fullpath')), 'cardiac_params_v2.m'));

mdl     = 'CardiacDigitalTwin_v2';
mdlFile = fullfile(fileparts(mfilename('fullpath')), [mdl '.slx']);

if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end

%% ── Run 1: Baseline dose ─────────────────────────────────────────────────
baseline_dose = 50;
fprintf('\n-- v2 Simulation 1 of 2: Baseline (dose = %g mg) --\n', baseline_dose);

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(baseline_dose));
simOut1 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');

t1   = simOut1.tout;
hr1  = simOut1.HR_out;
co1  = simOut1.CO_out;
map1 = simOut1.MAP_out;

ss1 = t1 > 0.9 * t1(end);
hr1_ss  = mean(hr1(ss1));
co1_ss  = mean(co1(ss1));
map1_ss = mean(map1(ss1));

%% ── Run 2: Modified dose (+20%) ──────────────────────────────────────────
modified_dose = baseline_dose * 1.20;
fprintf('-- v2 Simulation 2 of 2: Modified (+20%% dose = %g mg) --\n', modified_dose);

set_param([mdl '/BetaBlockerDose'], 'Value', num2str(modified_dose));
simOut2 = sim(mdl, 'ReturnWorkspaceOutputs', 'on');

t2   = simOut2.tout;
hr2  = simOut2.HR_out;
co2  = simOut2.CO_out;
map2 = simOut2.MAP_out;

ss2 = t2 > 0.9 * t2(end);
hr2_ss  = mean(hr2(ss2));
co2_ss  = mean(co2(ss2));
map2_ss = mean(map2(ss2));

% Restore the baseline dose so the model is left in a sensible state.
set_param([mdl '/BetaBlockerDose'], 'Value', num2str(baseline_dose));

%% ── Results table ────────────────────────────────────────────────────────
fprintf('\n==========================================================\n');
fprintf('  CARDIAC DIGITAL TWIN v2 -- SIMULATION RESULTS\n');
fprintf('  (Hill receptor binding + closed-loop baroreflex)\n');
fprintf('==========================================================\n');
fprintf('  Metric               Baseline (%gmg)  Modified (%gmg)  Delta\n', ...
    baseline_dose, modified_dose);
fprintf('  --------------------------------------------------------\n');
fprintf('  Heart Rate (bpm)     %-16.1f %-16.1f %+.1f (%.1f%%)\n', ...
    hr1_ss, hr2_ss, hr2_ss-hr1_ss, (hr2_ss-hr1_ss)/hr1_ss*100);
fprintf('  Cardiac Output(L/m)  %-16.2f %-16.2f %+.2f (%.1f%%)\n', ...
    co1_ss, co2_ss, co2_ss-co1_ss, (co2_ss-co1_ss)/co1_ss*100);
fprintf('  Mean Art. P. (mmHg)  %-16.1f %-16.1f %+.1f (%.1f%%)\n', ...
    map1_ss, map2_ss, map2_ss-map1_ss, (map2_ss-map1_ss)/map1_ss*100);
fprintf('==========================================================\n');
fprintf('  Notes:\n');
fprintf('  - v2 HR is higher than v1 at the same dose because the\n');
fprintf('    baroreflex partially compensates for the drug effect.\n');
fprintf('  - The marginal HR drop from %g to %g mg is smaller than\n', baseline_dose, modified_dose);
fprintf('    v1''s because the Hill curve saturates near Emax.\n');
fprintf('==========================================================\n\n');
