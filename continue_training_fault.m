% LEGACY: episode-level gain tuning, not online residual control.
% See residual_rl/ and README.md for the separate residual workflow.
%% continue_training_fault.m
% Resumes training for the FAULT scenario from trained_fault_agent.mat.
% Mirrors continue_training.m's proven pattern (kept separate so the
% two scenarios' agents never mix).

clear; clc;

modelName   = 'Fault_RLready_AC_Droop_four_Inverters';
simStopTime = 15;   % load change at t=6s needs the full 15s window to settle
agentFile   = 'trained_fault_agent.mat';

load_system(modelName);
set_param(modelName, 'FastRestart', 'off');

%% 1. Logging setup (safe to re-run)
set_param(modelName, 'ReturnWorkspaceOutputs', 'on');
for i = 1:4
    sigName = sprintf('w%d', i);
    if isempty(find_system(modelName,'SearchDepth',1,'Name',['From_' sigName]))
        add_block('simulink/Signal Routing/From', [modelName '/From_' sigName], ...
            'GotoTag', sigName, 'Position', [50+40*i 200 70+40*i 220]);
    end
    if isempty(find_system(modelName,'SearchDepth',1,'Name',['ToWorkspace_' sigName]))
        add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_' sigName], ...
            'VariableName', sigName, 'SaveFormat', 'Structure with time', ...
            'Position', [100+40*i 200 140+40*i 220]);
        add_line(modelName, ['From_' sigName '/1'], ['ToWorkspace_' sigName '/1'], ...
            'autorouting', 'on');
    end
end

%% 2. Recreate the environment
actInfo = rlNumericSpec([3 1], ...
    'LowerLimit', [0.5;  0.5e-4; 2.5], ...
    'UpperLimit', [2.0;  2.0e-4; 10.0]);
actInfo.Name = 'consensus_gains';

obsInfo = rlNumericSpec([4 1], 'LowerLimit', 0, 'UpperLimit', 5);
obsInfo.Name = 'freq_errors';

resetFcnHandle = @() deal(zeros(4,1), struct());
stepFcnHandle  = @(Action, LoggedSignals) stepFcn(Action, LoggedSignals, modelName, simStopTime);

env = rlFunctionEnv(obsInfo, actInfo, stepFcnHandle, resetFcnHandle);

%% 3. Load the saved fault-scenario agent (NOT a new one)
loaded = load(agentFile, 'agent');
agent = loaded.agent;
fprintf('Loaded fault-scenario agent with existing training progress.\n');

%% 4. Continue training in a short batch
trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 30, ...
    'MaxStepsPerEpisode', 1, ...
    'ScoreAveragingWindowLength', 10, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', -0.05, ...
    'SaveAgentCriteria', 'EpisodeFrequency', ...
    'SaveAgentValue', 10, ...
    'SaveAgentDirectory', ['savedAgents_fault_' datestr(now,'yyyymmdd_HHMM')]);

trainingStats = train(agent, env, trainOpts);

save(agentFile, 'agent', 'trainingStats');
fprintf('Fault-scenario training continued and saved.\n');

%% --- Local functions ---
function [Observation, Reward, IsDone, LoggedSignals] = stepFcn(Action, LoggedSignals, modelName, simStopTime)
    assignin('base', 'k_couple', Action(1));
    assignin('base', 'k_power',  Action(2));
    assignin('base', 'k_corr',   Action(3));

    set_param(modelName, 'StopTime', num2str(simStopTime));
    simOut = sim(modelName);

    itae = 0;
    finalErr = zeros(4,1);
    for i = 1:4
        sigName = sprintf('w%d', i);
        ts = getSignalValue(simOut, sigName);
        t = ts.Time;
        f_hz = ts.Data / (2*pi);
        err = abs(f_hz - 60);
        itae = itae + trapz(t, t .* err);
        finalErr(i) = err(end);
    end

    Reward = -itae;
    Observation = finalErr;
    IsDone = true;

    Simulink.sdi.clear;
end

function ts = getSignalValue(simOut, signalName)
    sig = simOut.get(signalName);
    if isa(sig, 'timeseries')
        ts.Time = sig.Time;
        ts.Data = sig.Data;
    elseif isa(sig, 'Simulink.SimulationData.Dataset')
        el = sig.get(signalName);
        ts.Time = el.Values.Time;
        ts.Data = el.Values.Data;
    elseif isstruct(sig) && isfield(sig, 'time') && isfield(sig, 'signals')
        ts.Time = sig.time;
        ts.Data = sig.signals.values;
    else
        error('Unrecognized signal format for %s', signalName);
    end
end
