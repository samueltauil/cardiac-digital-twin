%% cardiac_params_v2.m
% Workspace parameters for the advanced (v2) Cardiac Digital Twin model.
%
% The v2 model differs from v1 in two structural ways:
%
%   1. The HeartRateModel uses a Hill/Emax nonlinearity for receptor
%      binding instead of a linear gain. This captures the diminishing
%      marginal effect of higher beta-blocker doses as receptors saturate.
%
%   2. The model closes the cardiovascular loop with a BaroreflexController
%      that senses the deviation of mean arterial pressure (MAP) from a
%      setpoint and pushes HR back up via sympathetic activation. This is
%      why real patients on beta-blockers do not collapse: the autonomic
%      system partially compensates for the drug-induced HR drop.
%
% Run this script before opening CardiacDigitalTwin_v2.slx. All variables
% are loaded into the base workspace and referenced by block parameters.

%% ── Carry over v1 parameters that are still used ───────────────────────
% v2 reuses the PK time constant, baseline HR, stroke volume, SVR,
% and the dose value. We load them by running the v1 params file rather
% than duplicating values.
run(fullfile(fileparts(mfilename('fullpath')), 'cardiac_params.m'));

%% ── Hill/Emax receptor binding parameters ──────────────────────────────
% The drug effect is now nonlinear in plasma concentration:
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

%% ── Patient-cohort distributions (for run_patient_cohort.m) ────────────
% These define the population variability used by the Monte Carlo
% sweep. Values come from typical pharmacokinetic literature ranges
% for beta-blocker studies; they are illustrative, not patient data.
cohort_log_normal_sigma = 0.25;   % log-normal sigma for PK params
cohort_normal_cv        = 0.15;   % coefficient of variation for baseline HR

%% ── Print expected steady-state numbers for sanity-check ───────────────
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

fprintf('── Cardiac Digital Twin v2: Expected Steady-State (dose = %g mg) ──\n', C);
fprintf('  Hill drug effect: %.1f bpm (Emax %g, EC50 %g, n %.1f)\n', de, emax_bpm, ec50_mg, hill_n);
fprintf('  Open-loop:   HR %.1f bpm, CO %.2f L/min, MAP %.1f mmHg\n', hr_open,   co_open,   map_open);
fprintf('  Closed-loop: HR %.1f bpm, CO %.2f L/min, MAP %.1f mmHg (baroreflex)\n', ...
    hr_closed, co_closed, map_closed);
