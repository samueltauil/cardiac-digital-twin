%% run_patient_cohort.m
% Phase 2 prompt 11: Virtual patient cohort.
%
% Runs the v2 cardiac digital twin over a Monte Carlo cohort of synthetic
% patients. Each patient has independently sampled PK and physiology
% parameters drawn from population-style distributions. The script
% reports the steady-state distribution of HR, CO, and MAP at the
% baseline dose and the modified dose, so we can see how a population
% responds rather than just one nominal patient.
%
% Usage:
%   run('analysis/run_patient_cohort.m')
%
% Adjustable knobs:
%   nPatients - number of virtual patients (default 100)
%   doses     - row vector of doses in mg to evaluate (default [50 60])
%
% Outputs:
%   Workspace variable cohortResults (struct array) holds per-patient
%   parameter samples and steady-state results for both doses.

%% ── Setup ──────────────────────────────────────────────────────────────
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'model'));
addpath(fullfile(repoRoot, 'analysis'));

run(fullfile(repoRoot, 'model', 'cardiac_params_v2.m'));

mdl     = 'CardiacDigitalTwin_v2';
mdlFile = fullfile(repoRoot, 'model', [mdl '.slx']);
if ~bdIsLoaded(mdl)
    load_system(mdlFile);
end

%% ── Cohort definition ─────────────────────────────────────────────────
nPatients = 100;            % cohort size
doses     = [50 60];        % mg
rng(42);                    % reproducible cohort

% Nominal values come from the base workspace (loaded by cardiac_params_v2).
nominal.baseline_hr  = baseline_heart_rate;
nominal.beta_sens    = beta_hr_sensitivity;
nominal.pk_tau       = pk_time_constant;
nominal.emax         = emax_bpm;
nominal.ec50         = ec50_mg;
nominal.hill_n       = hill_n;
nominal.svr          = svr_mmHg_min_per_L;
nominal.sv           = stroke_volume_mL;

% Sample population variability:
%   Log-normal for pharmacokinetic parameters (positivity-preserving,
%   matches the right-skewed distribution typical of PK clearance).
%   Truncated normal for resting HR (symmetric around population mean).
sigma_log = cohort_log_normal_sigma;
cv_normal = cohort_normal_cv;

patients(nPatients) = struct( ...
    'pk_tau',[], 'emax',[], 'ec50',[], 'hill_n',[], ...
    'baseline_hr',[], 'sv',[], 'svr',[]);

for p = 1:nPatients
    patients(p).pk_tau      = nominal.pk_tau   * lognrnd(0, sigma_log);
    patients(p).emax        = nominal.emax     * lognrnd(0, sigma_log);
    patients(p).ec50        = nominal.ec50     * lognrnd(0, sigma_log);
    patients(p).hill_n      = max(0.5, nominal.hill_n * (1 + cv_normal * randn));
    patients(p).baseline_hr = max(50, nominal.baseline_hr * (1 + cv_normal * randn));
    patients(p).sv          = nominal.sv       * (1 + cv_normal * randn);
    patients(p).svr         = nominal.svr      * (1 + cv_normal * randn);
end

%% ── Build the SimulationInput array (parsim-friendly) ─────────────────
nDoses = numel(doses);
nRuns  = nPatients * nDoses;
inputs(1, nRuns) = Simulink.SimulationInput(mdl);

idx = 0;
for d = 1:nDoses
    for p = 1:nPatients
        idx = idx + 1;
        % setBlockParameter is used for the dose because the BetaBlockerDose
        % Constant block reads its value at compile time. setVariable on the
        % other PK and physiology parameters is enough because the blocks
        % using them are simple Gain/Constant references to the workspace.
        in = Simulink.SimulationInput(mdl) ...
            .setBlockParameter([mdl '/BetaBlockerDose'], 'Value', num2str(doses(d))) ...
            .setVariable('pk_time_constant',     patients(p).pk_tau) ...
            .setVariable('emax_bpm',             patients(p).emax) ...
            .setVariable('ec50_mg',              patients(p).ec50) ...
            .setVariable('hill_n',               patients(p).hill_n) ...
            .setVariable('baseline_heart_rate',  patients(p).baseline_hr) ...
            .setVariable('stroke_volume_mL',     patients(p).sv) ...
            .setVariable('svr_mmHg_min_per_L',   patients(p).svr) ...
            .setModelParameter('StopTime', '3600');
        inputs(idx) = in;
    end
end

%% ── Run the cohort ────────────────────────────────────────────────────
fprintf('\n-- Running cohort: %d patients x %d doses = %d simulations --\n', ...
    nPatients, nDoses, nRuns);
fprintf('(Falls back to sim() if Parallel Computing Toolbox is unavailable.)\n');

usePar = exist('parsim', 'file') == 2 && license('test', 'Distrib_Computing_Toolbox');
tic;
if usePar
    out = parsim(inputs, 'ShowProgress', 'on', 'UseFastRestart', 'on');
else
    out = arrayfun(@(in) sim(in), inputs);
end
elapsed = toc;
if usePar
    mode_str = 'parallel';
else
    mode_str = 'serial';
end
fprintf('Cohort completed in %.1f s (%s).\n', elapsed, mode_str);

%% ── Extract steady-state results ──────────────────────────────────────
cohortResults = struct('dose', cell(1, nRuns), 'patient', [], ...
    'hr_ss', [], 'co_ss', [], 'map_ss', []);

idx = 0;
for d = 1:nDoses
    for p = 1:nPatients
        idx = idx + 1;
        t  = out(idx).tout;
        hr = out(idx).HR_out;
        co = out(idx).CO_out;
        mp = out(idx).MAP_out;
        ss = t >= 0.9 * t(end);
        cohortResults(idx).dose    = doses(d);
        cohortResults(idx).patient = p;
        cohortResults(idx).hr_ss   = mean(hr(ss));
        cohortResults(idx).co_ss   = mean(co(ss));
        cohortResults(idx).map_ss  = mean(mp(ss));
    end
end

%% ── Population summary ────────────────────────────────────────────────
fprintf('\n=================================================================\n');
fprintf('  COHORT SUMMARY (n = %d patients per dose)\n', nPatients);
fprintf('=================================================================\n');
fprintf('  Dose        HR (bpm)            CO (L/min)        MAP (mmHg)\n');
fprintf('              mean +/- sd         mean +/- sd       mean +/- sd\n');
fprintf('  -----------------------------------------------------------------\n');
for d = 1:nDoses
    mask = arrayfun(@(r) r.dose == doses(d), cohortResults);
    hr_v = [cohortResults(mask).hr_ss];
    co_v = [cohortResults(mask).co_ss];
    mp_v = [cohortResults(mask).map_ss];
    fprintf('  %2g mg       %5.1f +/- %4.1f      %4.2f +/- %4.2f      %5.1f +/- %4.1f\n', ...
        doses(d), mean(hr_v), std(hr_v), mean(co_v), std(co_v), mean(mp_v), std(mp_v));
end
fprintf('=================================================================\n');
fprintf('Workspace variable cohortResults holds per-patient steady-state.\n');
fprintf('Run analysis/sensitivity_tornado.m to see which parameters\n');
fprintf('dominate the HR response across this cohort.\n');
fprintf('=================================================================\n\n');

assignin('base', 'cohortResults', cohortResults);
assignin('base', 'patients',      patients);
