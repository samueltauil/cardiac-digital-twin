%% create_cardiac_model.m
% Builds CardiacDigitalTwin.slx programmatically.
%
% The model is a four-stage pharmacological cascade with a closed
% baroreflex feedback loop:
%
%   1. BetaBlockerPK
%        First-order PK that converts oral dose (mg) to plasma
%        concentration via a 1/(tau*s + 1) transfer function.
%
%   2. HeartRateModel (Hill/Emax receptor binding + baroreflex input)
%        DrugEffect = Emax * C^n / (EC50^n + C^n)
%        HR = baseline_heart_rate - DrugEffect + BaroreflexCorrection
%      Captures receptor saturation at higher doses (the marginal HR
%      drop shrinks as dose rises).
%
%   3. CardiacOutputModel
%        CO = HR * SV / 1000 (L/min)
%
%   4. BloodPressureModel
%        MAP = CO * SVR (mmHg)
%
%   5. BaroreflexController (closed feedback)
%        MAP_error = map_setpoint - MAP
%        HR_correction = baroreflex_gain * MAP_error (first-order lag)
%      Routes back into HeartRateModel as a second input. The drug
%      lowers HR, which lowers MAP, which the baroreflex senses and
%      partially compensates by raising HR. This is the autonomic loop
%      that keeps real patients on beta-blockers haemodynamically stable.
%
% Prerequisites:
%   - Run setup/startup.m first
%   - cardiac_params.m has been loaded into base workspace
%
% Architecture (open-loop view; baroreflex closes from MAP back to HR):
%
%   Dose -> [PK] -> [HR (Hill + baro)] -> [CO] -> [BP] -> MAP
%                          ^                                 |
%                          +------ [BaroreflexController] <--+

%% ── Ensure parameters are loaded ────────────────────────────────────────
if ~exist('emax_bpm', 'var')
    run(fullfile(fileparts(mfilename('fullpath')), 'cardiac_params.m'));
end

%% ── Model setup ──────────────────────────────────────────────────────────
mdl = 'CardiacDigitalTwin';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
open_system(mdl);

set_param(mdl, ...
    'Solver',      'ode45', ...
    'StopTime',    '3600', ...   % 1-hour simulation window
    'MaxStep',     '10', ...
    'SolverType',  'Variable-step');

%% ════════════════════════════════════════════════════════════════════════
%% TOP-LEVEL BLOCKS
%% ════════════════════════════════════════════════════════════════════════

%% Dose input ──────────────────────────────────────────────────────────────
add_block('simulink/Sources/Constant', [mdl '/BetaBlockerDose'], ...
    'Value',    'beta_blocker_dose_mg', ...
    'Position', blockPos(1, 2));

%% Subsystems ──────────────────────────────────────────────────────────────
add_block('built-in/Subsystem', [mdl '/BetaBlockerPK'],         'Position', blockPos(2, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/HeartRateModel'],        'Position', blockPos(3, 2, 100, 70));
add_block('built-in/Subsystem', [mdl '/CardiacOutputModel'],    'Position', blockPos(4, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/BloodPressureModel'],    'Position', blockPos(5, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/BaroreflexController'],  'Position', blockPos(4, 4, 130, 60));

%% Output scopes ───────────────────────────────────────────────────────────
add_block('simulink/Sinks/Scope', [mdl '/HeartRateScope'],     'Position', blockPos(3, 1, 60, 40));
add_block('simulink/Sinks/Scope', [mdl '/CardiacOutputScope'], 'Position', blockPos(4, 1, 60, 40));
add_block('simulink/Sinks/Scope', [mdl '/BloodPressureScope'], 'Position', blockPos(5, 1, 60, 40));

%% To Workspace blocks (for programmatic validation and cohort analysis) ──
add_block('simulink/Sinks/To Workspace', [mdl '/HR_out'], ...
    'VariableName', 'HR_out',  'SaveFormat', 'Array', 'Position', blockPos(3, 6, 80, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/CO_out'], ...
    'VariableName', 'CO_out',  'SaveFormat', 'Array', 'Position', blockPos(4, 6, 80, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/MAP_out'], ...
    'VariableName', 'MAP_out', 'SaveFormat', 'Array', 'Position', blockPos(5, 6, 80, 30));

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: BetaBlockerPK
%% Same first-order PK model as v1.
%% Transfer function: C(s)/D(s) = 1 / (pk_time_constant*s + 1)
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/BetaBlockerPK'];

add_block('built-in/Inport',  [ss '/DoseIn'],         'Port', '1', 'Position', [30 83 60 117]);
add_block('simulink/Continuous/Transfer Fcn', [ss '/PKTransferFcn'], ...
    'Numerator',    '[1]', ...
    'Denominator',  '[pk_time_constant 1]', ...
    'Position', [110 80 230 120]);
add_block('built-in/Outport', [ss '/ConcentrationOut'], 'Port', '1', 'Position', [290 83 320 117]);

add_line(ss, 'DoseIn/1',        'PKTransferFcn/1');
add_line(ss, 'PKTransferFcn/1', 'ConcentrationOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: HeartRateModel (v2 - nonlinear with feedback)
%% HR = baseline - HillEffect(concentration) + BaroreflexCorrection
%% Clamped to physiological range [40, 180] bpm
%%
%% Two inports now:
%%   1. ConcentrationIn  (from BetaBlockerPK)
%%   2. BaroreflexIn     (from BaroreflexController, closed feedback)
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/HeartRateModel'];

add_block('built-in/Inport', [ss '/ConcentrationIn'], 'Port', '1', 'Position', [30  60  60  90]);
add_block('built-in/Inport', [ss '/BaroreflexIn'],    'Port', '2', 'Position', [30 220  60 250]);

% Hill/Emax nonlinearity. The Fcn block evaluates a math expression in u.
% u here is the plasma concentration; emax_bpm, ec50_mg, hill_n come from
% the base workspace.
add_block('simulink/User-Defined Functions/Fcn', [ss '/HillEquation'], ...
    'Expr', 'emax_bpm*u^hill_n/(ec50_mg^hill_n + u^hill_n)', ...
    'Position', [110 55 230 95]);

% Baseline HR constant.
add_block('simulink/Sources/Constant', [ss '/BaselineHR'], ...
    'Value', 'baseline_heart_rate', 'Position', [30 140 130 170]);

% Sum: baseline - HillEffect + BaroreflexCorrection.
% Sign string: '+-+' maps to {BaselineHR, HillEffect, BaroreflexIn}.
add_block('simulink/Math Operations/Sum', [ss '/HRSum'], ...
    'Inputs', '+-+', 'Position', [290 90 330 220]);

add_block('simulink/Discontinuities/Saturation', [ss '/HRClamp'], ...
    'UpperLimit', '180', 'LowerLimit', '40', 'Position', [380 135 460 175]);

add_block('built-in/Outport', [ss '/HeartRateOut'], 'Port', '1', 'Position', [510 143 540 167]);

add_line(ss, 'ConcentrationIn/1', 'HillEquation/1');
add_line(ss, 'BaselineHR/1',      'HRSum/1');
add_line(ss, 'HillEquation/1',    'HRSum/2');
add_line(ss, 'BaroreflexIn/1',    'HRSum/3');
add_line(ss, 'HRSum/1',           'HRClamp/1');
add_line(ss, 'HRClamp/1',         'HeartRateOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: CardiacOutputModel (unchanged from v1)
%% CO (L/min) = HR (bpm) * SV (mL/beat) / 1000
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/CardiacOutputModel'];

add_block('built-in/Inport',  [ss '/HeartRateIn'], 'Port', '1', 'Position', [30 83 60 117]);

add_block('simulink/Sources/Constant', [ss '/StrokeVolume'], ...
    'Value', 'stroke_volume_mL', 'Position', [30 170 140 200]);
add_block('simulink/Math Operations/Product', [ss '/COProduct'], ...
    'Inputs', '**', 'Position', [150 95 210 155]);
add_block('simulink/Math Operations/Gain', [ss '/mLtoL'], ...
    'Gain', '1/1000', 'Position', [270 105 360 145]);

add_block('built-in/Outport', [ss '/CardiacOutputOut'], 'Port', '1', 'Position', [430 113 460 137]);

add_line(ss, 'HeartRateIn/1',   'COProduct/1');
add_line(ss, 'StrokeVolume/1',  'COProduct/2');
add_line(ss, 'COProduct/1',     'mLtoL/1');
add_line(ss, 'mLtoL/1',         'CardiacOutputOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: BloodPressureModel (unchanged from v1)
%% MAP (mmHg) = CO (L/min) * SVR (mmHg*min/L)
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/BloodPressureModel'];

add_block('built-in/Inport',  [ss '/CardiacOutputIn'], 'Port', '1', 'Position', [30 83 60 117]);
add_block('simulink/Math Operations/Gain', [ss '/SVRGain'], ...
    'Gain', 'svr_mmHg_min_per_L', 'Position', [110 80 220 120]);
add_block('built-in/Outport', [ss '/MAPOut'], 'Port', '1', 'Position', [290 83 320 117]);

add_line(ss, 'CardiacOutputIn/1', 'SVRGain/1');
add_line(ss, 'SVRGain/1',         'MAPOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: BaroreflexController  (NEW in v2)
%%
%% HR_correction = baroreflex_gain * (map_setpoint - MAP),
%% filtered through a first-order lag with time constant baroreflex_tau.
%%
%% Negative MAP deviation (drug lowered the pressure) gives a positive
%% HR_correction that gets summed back into HeartRateModel and raises HR.
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/BaroreflexController'];

add_block('built-in/Inport', [ss '/MAPIn'], 'Port', '1', 'Position', [30 83 60 117]);

add_block('simulink/Sources/Constant', [ss '/MAPSetpoint'], ...
    'Value', 'map_setpoint_mmHg', 'Position', [30 160 140 190]);

% Sum: setpoint - MAP gives the pressure deviation.
add_block('simulink/Math Operations/Sum', [ss '/MAPError'], ...
    'Inputs', '+-', 'Position', [180 110 220 170]);

add_block('simulink/Math Operations/Gain', [ss '/BaroreflexGain'], ...
    'Gain', 'baroreflex_gain', 'Position', [260 115 360 165]);

% First-order lag for autonomic response time.
add_block('simulink/Continuous/Transfer Fcn', [ss '/BaroreflexLag'], ...
    'Numerator',    '[1]', ...
    'Denominator',  '[baroreflex_tau 1]', ...
    'Position', [400 115 520 165]);

add_block('built-in/Outport', [ss '/HRCorrectionOut'], 'Port', '1', 'Position', [560 128 590 152]);

add_line(ss, 'MAPSetpoint/1',    'MAPError/1');
add_line(ss, 'MAPIn/1',          'MAPError/2');
add_line(ss, 'MAPError/1',       'BaroreflexGain/1');
add_line(ss, 'BaroreflexGain/1', 'BaroreflexLag/1');
add_line(ss, 'BaroreflexLag/1',  'HRCorrectionOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% TOP-LEVEL WIRING (with closed baroreflex loop)
%% ════════════════════════════════════════════════════════════════════════
add_line(mdl, 'BetaBlockerDose/1',       'BetaBlockerPK/1');
add_line(mdl, 'BetaBlockerPK/1',         'HeartRateModel/1');
add_line(mdl, 'HeartRateModel/1',        'CardiacOutputModel/1');
add_line(mdl, 'CardiacOutputModel/1',    'BloodPressureModel/1');

% Closed feedback: MAP -> BaroreflexController -> HeartRateModel(in2)
add_line(mdl, 'BloodPressureModel/1',    'BaroreflexController/1', 'autorouting', 'on');
add_line(mdl, 'BaroreflexController/1',  'HeartRateModel/2',       'autorouting', 'on');

% Scopes and To Workspace taps.
add_line(mdl, 'HeartRateModel/1',        'HeartRateScope/1');
add_line(mdl, 'CardiacOutputModel/1',    'CardiacOutputScope/1');
add_line(mdl, 'BloodPressureModel/1',    'BloodPressureScope/1');

add_line(mdl, 'HeartRateModel/1',        'HR_out/1');
add_line(mdl, 'CardiacOutputModel/1',    'CO_out/1');
add_line(mdl, 'BloodPressureModel/1',    'MAP_out/1');

%% ── Save ─────────────────────────────────────────────────────────────────
modelFile = fullfile(fileparts(mfilename('fullpath')), [mdl '.slx']);
save_system(mdl, modelFile);
fprintf('Model saved: %s\n', modelFile);
fprintf('Open in MATLAB: open_system(''%s'')\n', modelFile);

%% ════════════════════════════════════════════════════════════════════════
%% LOCAL FUNCTIONS (must be at end of script)
%% ════════════════════════════════════════════════════════════════════════

function pos = blockPos(col, row, w, h)
% Returns a [left top right bottom] position vector for a block at grid
% position (col, row) with optional width w and height h.
    x = 80 + (col - 1) * 200;
    y = 80 + (row - 1) * 130;
    if nargin < 3, w = 80; end
    if nargin < 4, h = 40; end
    pos = [x, y, x+w, y+h];
end
