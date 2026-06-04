%% cardiac_params.m
% Workspace parameters for the Cardiac Digital Twin model.
% Run this script (or call from startup.m) before opening the model.
% All variables are loaded into the base workspace and referenced
% directly by Simulink block parameters.

%% ── Pharmacokinetics ─────────────────────────────────────────────────────
% First-order absorption / elimination model for oral metoprolol.
% At steady state, plasma concentration equals the dose value.
pk_time_constant = 1800;     % seconds  (≈ 30-min half-life for demo)

%% ── Baseline physiology (no medication) ─────────────────────────────────
baseline_heart_rate  = 75;   % bpm      (resting HR, drug-free)
stroke_volume_mL     = 70;   % mL/beat  (average resting stroke volume)
svr_mmHg_min_per_L   = 18;   % mmHg·min/L (systemic vascular resistance)
                              %  MAP = CO × SVR
                              %  At CO = 5.25 L/min → MAP ≈ 94.5 mmHg ✓

%% ── Beta-blocker (metoprolol) dosing ─────────────────────────────────────
beta_blocker_dose_mg = 50;   % mg  — CURRENT DOSE (demo: change to 60 mg)

% Sensitivity: HR reduction per mg of metoprolol at steady state.
% Calibrated so 50 mg → ≈ 12 bpm reduction (HR 75 → 63 bpm),
% consistent with clinical metoprolol succinate 50 mg/day data.
beta_hr_sensitivity  = 0.24; % bpm / mg

%% ── Derived expected steady-state values (for validation reference) ──────
% These are not used by Simulink directly; they document expected outputs.
expected_HR_baseline_bpm = baseline_heart_rate - beta_hr_sensitivity * beta_blocker_dose_mg;
expected_CO_baseline_Lmin = expected_HR_baseline_bpm * stroke_volume_mL / 1000;
expected_MAP_baseline_mmHg = expected_CO_baseline_Lmin * svr_mmHg_min_per_L;

fprintf('── Cardiac Digital Twin: Expected Steady-State (dose = %g mg) ──\n', beta_blocker_dose_mg);
fprintf('  Heart Rate      : %.1f bpm\n',   expected_HR_baseline_bpm);
fprintf('  Cardiac Output  : %.2f L/min\n', expected_CO_baseline_Lmin);
fprintf('  Mean Art. Press.: %.1f mmHg\n',  expected_MAP_baseline_mmHg);
