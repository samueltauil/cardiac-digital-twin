%% realtime_dashboard.m
% Real-time HR / CO / MAP dashboard for the cardiac digital twin.
% Runs the 50 mg baseline and the 60 mg modified dose back-to-back, with
% Simulink Pacing enabled so the model plays out in close-to-real time.
% Three gauges show the *current* haemodynamic state while three axes
% accumulate both runs in different colours for a side-by-side comparison.
%
% Usage:
%   realtime_dashboard           % runs both doses, default pace
%   realtime_dashboard(0.002)    % faster (2 ms wall per sim-sec)
%
% Prerequisites:
%   - setup/startup.m has been run (parameters in base workspace,
%     CardiacDigitalTwin.slx built and findable on path)

function realtime_dashboard(paceRate)
arguments
    paceRate (1,1) double {mustBePositive} = 0.005   % wall sec / sim sec
end

mdl = 'CardiacDigitalTwin';
if ~bdIsLoaded(mdl)
    load_system(mdl);
end

% ── Configure pacing ─────────────────────────────────────────────────────
% PaceRate = 0.005 ⇒ 5 ms wall-clock per simulation second
% StopTime = 3600 s ⇒ ~18 s wall per run, ~36 s wall total
prevPace   = get_param(mdl, 'EnablePacing');
prevStop   = get_param(mdl, 'StopTime');
prevDose   = evalin('base', 'beta_blocker_dose_mg');
cleaner    = onCleanup(@() restoreState(mdl, prevPace, prevStop, prevDose));

set_param(mdl, 'EnablePacing', 'on', ...
               'PaceRate',     num2str(paceRate), ...
               'StopTime',     '3600');

% ── Build dashboard UI ───────────────────────────────────────────────────
fig = uifigure('Name', 'Cardiac Digital Twin — Real-Time Dashboard', ...
               'Position', [80 80 1180 760], ...
               'Color',    [0.97 0.97 0.99]);

gl = uigridlayout(fig, [3 3], ...
    'RowHeight',   {230, '1x', 90}, ...
    'ColumnWidth', {'1x', '1x', '1x'}, ...
    'Padding',     [12 12 12 12], ...
    'RowSpacing',  10, 'ColumnSpacing', 10);

g_hr  = makeGauge(gl, 'Heart Rate (bpm)',          40, 100, [55  75]);
g_co  = makeGauge(gl, 'Cardiac Output (L/min)',    2.5, 8.0, [4.0 6.0]);
g_map = makeGauge(gl, 'Mean Art. Pressure (mmHg)', 55, 110, [70 105]);

ax_hr  = makeAxes(gl, 'Heart Rate (bpm) — t (min)',        [40 100]);
ax_co  = makeAxes(gl, 'Cardiac Output (L/min) — t (min)',  [3.0  6.0]);
ax_map = makeAxes(gl, 'Mean Art. Pressure (mmHg) — t (min)', [60  100]);

lbl_run   = uilabel(gl, 'Text', 'Status: ready',                'FontSize', 16, 'FontWeight', 'bold');
lbl_delta = uilabel(gl, 'Text', 'Δ steady-state (60 vs 50): –', 'FontSize', 14);
uibutton(gl, 'Text', 'Close', 'FontSize', 14, ...
             'ButtonPushedFcn', @(~,~) close(fig));

% ── Run both doses ───────────────────────────────────────────────────────
doses  = [50, 60];
labels = {'Baseline 50 mg', 'Increased 60 mg'};
colors = {[0.85 0.22 0.20], [0.20 0.45 0.85]};

hrSS  = nan(1,2);
coSS  = nan(1,2);
mapSS = nan(1,2);

for k = 1:numel(doses)
    assignin('base', 'beta_blocker_dose_mg', doses(k));
    lbl_run.Text = sprintf('Status: running %s  (pace = %g s/s)', labels{k}, paceRate);
    drawnow;

    ln_hr  = animatedline(ax_hr,  'Color', colors{k}, 'LineWidth', 2.0);
    ln_co  = animatedline(ax_co,  'Color', colors{k}, 'LineWidth', 2.0);
    ln_map = animatedline(ax_map, 'Color', colors{k}, 'LineWidth', 2.0);

    set_param(mdl, 'SimulationCommand', 'start');

    % Live poll loop — read RuntimeObjects until simulation finishes
    lastT = -inf;
    while ~strcmp(get_param(mdl, 'SimulationStatus'), 'stopped')
        rto_hr  = get_param([mdl '/HeartRateModel'],     'RuntimeObject');
        rto_co  = get_param([mdl '/CardiacOutputModel'], 'RuntimeObject');
        rto_map = get_param([mdl '/BloodPressureModel'], 'RuntimeObject');
        tNow    = get_param(mdl, 'SimulationTime');

        if ~isempty(rto_hr) && tNow > lastT
            hr  = rto_hr.OutputPort(1).Data;
            co  = rto_co.OutputPort(1).Data;
            map = rto_map.OutputPort(1).Data;
            g_hr.Value  = hr;
            g_co.Value  = co;
            g_map.Value = map;
            addpoints(ln_hr,  tNow/60, hr);
            addpoints(ln_co,  tNow/60, co);
            addpoints(ln_map, tNow/60, map);
            drawnow limitrate;
            lastT = tNow;
        end
        pause(0.05);
    end

    % Sim finished — collect To Workspace results from base workspace
    t   = evalin('base', 'tout');
    HR  = evalin('base', 'HR_out');
    CO  = evalin('base', 'CO_out');
    MAP = evalin('base', 'MAP_out');
    ssMask    = t >= 0.9 * t(end);
    hrSS(k)   = mean(HR(ssMask));
    coSS(k)   = mean(CO(ssMask));
    mapSS(k)  = mean(MAP(ssMask));

    % Make sure the final values are reflected on the gauges
    g_hr.Value  = HR(end);
    g_co.Value  = CO(end);
    g_map.Value = MAP(end);
end

% Add legends now that both runs are drawn
legend(ax_hr,  labels, 'Location', 'southeast', 'FontSize', 10);
legend(ax_co,  labels, 'Location', 'southeast', 'FontSize', 10);
legend(ax_map, labels, 'Location', 'southeast', 'FontSize', 10);

dHR  = hrSS(2)  - hrSS(1);
dCO  = coSS(2)  - coSS(1);
dMAP = mapSS(2) - mapSS(1);
lbl_run.Text = 'Status: comparison complete';
lbl_delta.Text = sprintf( ...
    ['Δ steady-state (60 mg vs 50 mg):  ' ...
     'HR  %+0.2f bpm   |   CO  %+0.3f L/min   |   MAP  %+0.2f mmHg'], ...
     dHR, dCO, dMAP);
end

%% ── helpers ─────────────────────────────────────────────────────────────
function g = makeGauge(parent, ttl, lo, hi, safeBand)
    p = uipanel(parent, 'Title', ttl, 'FontWeight', 'bold', 'FontSize', 12);
    pl = uigridlayout(p, [1 1], 'Padding', [4 4 4 4]);
    g = uigauge(pl, 'Limits', [lo hi], ...
        'ScaleColors',      {[1 0.5 0.5], [0.6 0.85 0.6], [1 0.5 0.5]}, ...
        'ScaleColorLimits', [lo safeBand(1); safeBand(1) safeBand(2); safeBand(2) hi]);
end

function ax = makeAxes(parent, ttl, yLim)
    p = uipanel(parent);
    pl = uigridlayout(p, [1 1], 'Padding', [4 4 4 4]);
    ax = uiaxes(pl);
    title(ax, ttl);
    xlabel(ax, 'Time (min)');
    ylim(ax, yLim);
    grid(ax, 'on');
end

function restoreState(mdl, prevPace, prevStop, prevDose)
    if bdIsLoaded(mdl)
        set_param(mdl, 'EnablePacing', prevPace, 'StopTime', prevStop);
    end
    assignin('base', 'beta_blocker_dose_mg', prevDose);
end
