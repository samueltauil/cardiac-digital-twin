%% cardiac_params.m
% Workspace parameters for the Cardiac Digital Twin model.
% Run this script (or call it from setup/startup.m) before opening the
% model. All variables are loaded into the base workspace and referenced
% directly by Simulink block parameters.
%
% The model is a four-stage pharmacological cascade with a closed
% baroreflex feedback loop:
%
%   Dose -> [PK] -> [HR (Hill effect + baroreflex)] -> [CO] -> [BP] -> MAP
%                          ^                                            |
%                          +-------- [BaroreflexController] <-----------+
%
% Heart-rate response is modelled with a Hill/Emax saturable receptor
% binding, and the autonomic loop partially compensates for the drug
% effect by raising HR when MAP drops below setpoint.

%% ── Pharmacokinetics ─────────────────────────────────────────────────────
% First-order absorption / elimination model for oral metoprolol.
% At steady state, plasma concentration equals the dose value (mg).
pk_time_constant = 1800;     % seconds  (≈ 30-min half-life for demo)

%% ── Baseline physiology (no medication) ─────────────────────────────────
baseline_heart_rate  = 75;   % bpm      (resting HR, drug-free)
stroke_volume_mL     = 70;   % mL/beat  (average resting stroke volume)
svr_mmHg_min_per_L   = 18;   % mmHg·min/L (systemic vascular resistance)
                              %  MAP = CO * SVR
                              %  At CO = 5.25 L/min  ->  MAP ≈ 94.5 mmHg

%% ── Beta-blocker (metoprolol) dosing ─────────────────────────────────────
% Current daily dose. The demo workflow increases this by 20%
% (50 mg -> 60 mg) and compares haemodynamic outputs.
beta_blocker_dose_mg = 60;   % mg

%% ── Hill/Emax receptor binding parameters ──────────────────────────────
% Drug effect on heart rate is nonlinear in plasma concentration:
%
%   DrugEffect(C) = Emax * C^n / (EC50^n + C^n)
%
% At low C the response is roughly linear in C. As C approaches and
% exceeds EC50, the response saturates toward Emax. n controls the
% sharpness of the transition (n=1 is classical Michaelis-Menten,
% n>1 is cooperative binding).
emax_bpm  = 18;     % bpm. Maximum HR reduction the drug can ever cause.
ec50_mg   = 35;     % mg.  Plasma concentration giving half-maximal effect.
hill_n    = 1.5;    % dimensionless. Hill coefficient (cooperativity).

%% ── Baroreflex feedback parameters ─────────────────────────────────────
% The baroreflex senses the deviation of MAP from setpoint and applies
% a corrective HR adjustment. Positive deviation (MAP too high) lowers
% HR; negative deviation (MAP too low, as caused by the beta-blocker)
% raises HR. The gain is small but enough to noticeably compensate.
map_setpoint_mmHg = 94;     % mmHg.   Target arterial pressure.
baroreflex_gain   = 0.30;   % bpm per mmHg. Proportional gain.
baroreflex_tau    = 60;     % seconds. First-order lag of the autonomic loop.

%% ── Patient-cohort distributions (for analysis/run_patient_cohort.m) ───
% These define the population variability used by the Monte Carlo
% sweep. Values come from typical pharmacokinetic literature ranges
% for beta-blocker studies; they are illustrative, not patient data.
cohort_log_normal_sigma = 0.25;   % log-normal sigma for PK parameters
cohort_normal_cv        = 0.15;   % coefficient of variation for physiology

%% ── Print expected steady-state numbers for sanity check ───────────────
% These come from a hand-calculated solve of the closed-loop equations
% at the current dose and serve as a quick "did the model load right?"
% indicator when the script is sourced from the command line.
C  = beta_blocker_dose_mg;
de = emax_bpm * C^hill_n / (ec50_mg^hill_n + C^hill_n);

% Open-loop (no baroreflex) approximations:
hr_open  = baseline_heart_rate - de;
co_open  = hr_open * stroke_volume_mL / 1000;
map_open = co_open * svr_mmHg_min_per_L;

% First-order closed-loop correction:
baro_correction = baroreflex_gain * (map_setpoint_mmHg - map_open);
hr_closed  = hr_open  + baro_correction;
co_closed  = hr_closed * stroke_volume_mL / 1000;
map_closed = co_closed * svr_mmHg_min_per_L;

fprintf('── Cardiac Digital Twin: Expected Steady-State (dose = %g mg) ──\n', C);
fprintf('  Hill drug effect: %.1f bpm (Emax %g, EC50 %g, n %.1f)\n', de, emax_bpm, ec50_mg, hill_n);
fprintf('  Open-loop:   HR %.1f bpm, CO %.2f L/min, MAP %.1f mmHg\n', hr_open,   co_open,   map_open);
fprintf('  Closed-loop: HR %.1f bpm, CO %.2f L/min, MAP %.1f mmHg (baroreflex)\n', ...
    hr_closed, co_closed, map_closed);
