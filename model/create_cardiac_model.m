%% create_cardiac_model.m
% Builds the CardiacDigitalTwin.slx Simulink model programmatically.
%
% Prerequisites:
%   - Run setup/startup.m first (loads cardiac_params into base workspace)
%   - MATLAB R2023a+ with Simulink
%
% Model architecture (four subsystems):
%
%   BetaBlockerDose ──► [BetaBlockerPK] ──► [HeartRateModel] ──► [CardiacOutputModel] ──► [BloodPressureModel]
%                                                                        │                         │
%                                                                  HeartRateOut              CardiacOutputOut, MAPOut
%

%% ── Ensure parameters are loaded ────────────────────────────────────────
if ~exist('beta_blocker_dose_mg', 'var')
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
add_block('built-in/Subsystem', [mdl '/BetaBlockerPK'],       'Position', blockPos(2, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/HeartRateModel'],      'Position', blockPos(3, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/CardiacOutputModel'],  'Position', blockPos(4, 2, 100, 50));
add_block('built-in/Subsystem', [mdl '/BloodPressureModel'],  'Position', blockPos(5, 2, 100, 50));

%% Output scopes ───────────────────────────────────────────────────────────
add_block('simulink/Sinks/Scope', [mdl '/HeartRateScope'], ...
    'Position', blockPos(3, 4, 60, 40));
add_block('simulink/Sinks/Scope', [mdl '/CardiacOutputScope'], ...
    'Position', blockPos(4, 4, 60, 40));
add_block('simulink/Sinks/Scope', [mdl '/BloodPressureScope'], ...
    'Position', blockPos(5, 4, 60, 40));

%% To Workspace blocks (for programmatic validation) ──────────────────────
add_block('simulink/Sinks/To Workspace', [mdl '/HR_out'], ...
    'VariableName', 'HR_out', 'SaveFormat', 'Array', 'Position', blockPos(3, 5, 80, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/CO_out'], ...
    'VariableName', 'CO_out', 'SaveFormat', 'Array', 'Position', blockPos(4, 5, 80, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/MAP_out'], ...
    'VariableName', 'MAP_out', 'SaveFormat', 'Array', 'Position', blockPos(5, 5, 80, 30));

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: BetaBlockerPK
%% First-order pharmacokinetic model: dose → plasma concentration
%% Transfer function: C(s)/D(s) = 1 / (pk_time_constant·s + 1)
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
%% SUBSYSTEM: HeartRateModel
%% HR = baseline_heart_rate − beta_hr_sensitivity × plasma_concentration
%% Clamped to physiological range [40, 180] bpm
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/HeartRateModel'];

add_block('built-in/Inport',  [ss '/ConcentrationIn'], 'Port', '1', 'Position', [30 83 60 117]);

add_block('simulink/Sources/Constant', [ss '/BaselineHR'], ...
    'Value', 'baseline_heart_rate', 'Position', [30 170 130 200]);
add_block('simulink/Math Operations/Gain', [ss '/BetaSensitivity'], ...
    'Gain', 'beta_hr_sensitivity', 'Position', [110 75 200 115]);
add_block('simulink/Math Operations/Sum', [ss '/HRSum'], ...
    'Inputs', '+-', 'Position', [260 100 300 160]);
add_block('simulink/Discontinuities/Saturation', [ss '/HRClamp'], ...
    'UpperLimit', '180', 'LowerLimit', '40', 'Position', [350 105 430 145]);

add_block('built-in/Outport', [ss '/HeartRateOut'], 'Port', '1', 'Position', [490 113 520 137]);

add_line(ss, 'ConcentrationIn/1', 'BetaSensitivity/1');
add_line(ss, 'BaselineHR/1',      'HRSum/1');
add_line(ss, 'BetaSensitivity/1', 'HRSum/2');
add_line(ss, 'HRSum/1',           'HRClamp/1');
add_line(ss, 'HRClamp/1',         'HeartRateOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% SUBSYSTEM: CardiacOutputModel
%% CO (L/min) = HR (bpm) × SV (mL/beat) × (1 L / 1000 mL)
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
%% SUBSYSTEM: BloodPressureModel
%% MAP (mmHg) = CO (L/min) × SVR (mmHg·min/L)
%% ════════════════════════════════════════════════════════════════════════
ss = [mdl '/BloodPressureModel'];

add_block('built-in/Inport',  [ss '/CardiacOutputIn'], 'Port', '1', 'Position', [30 83 60 117]);

add_block('simulink/Math Operations/Gain', [ss '/SVRGain'], ...
    'Gain', 'svr_mmHg_min_per_L', 'Position', [110 80 220 120]);

add_block('built-in/Outport', [ss '/MAPOut'], 'Port', '1', 'Position', [290 83 320 117]);

add_line(ss, 'CardiacOutputIn/1', 'SVRGain/1');
add_line(ss, 'SVRGain/1',         'MAPOut/1');

%% ════════════════════════════════════════════════════════════════════════
%% TOP-LEVEL WIRING
%% ════════════════════════════════════════════════════════════════════════
add_line(mdl, 'BetaBlockerDose/1',   'BetaBlockerPK/1');
add_line(mdl, 'BetaBlockerPK/1',     'HeartRateModel/1');
add_line(mdl, 'HeartRateModel/1',    'CardiacOutputModel/1');
add_line(mdl, 'CardiacOutputModel/1','BloodPressureModel/1');

add_line(mdl, 'HeartRateModel/1',    'HeartRateScope/1');
add_line(mdl, 'CardiacOutputModel/1','CardiacOutputScope/1');
add_line(mdl, 'BloodPressureModel/1','BloodPressureScope/1');

add_line(mdl, 'HeartRateModel/1',    'HR_out/1');
add_line(mdl, 'CardiacOutputModel/1','CO_out/1');
add_line(mdl, 'BloodPressureModel/1','MAP_out/1');

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
    y = 80 + (row - 1) * 120;
    if nargin < 3, w = 80; end
    if nargin < 4, h = 40; end
    pos = [x, y, x+w, y+h];
end
