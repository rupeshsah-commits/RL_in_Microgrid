% LEGACY: episode-level gain tuning, not online residual control.
% See residual_rl/ and README.md for the separate residual workflow.
%% train_rl_fault_gains.m
% Fresh-start RL training for the FAULT scenario model (load increment
% at 6s instead of 4s). Assumes this model is a copy of your already-
% parametrized AC_Droop_four_Inverters_RLready.slx, so k_couple/k_power/
% k_corr and the w1-w4 logging blocks already exist -- this script does
% NOT touch prepare_model_for_RL.m's changes again.
%
% This is a fresh agent (not continuing from your other scenario's
% agent) since the two scenarios are separate research results. All
% fixes learned from the other scenario are included from the start:
% noise decay, Simulink.sdi.clear (memory fix), Fast Restart off,
% timestamped checkpointing.

clear; clc;

modelName    = 'Fault_RLready_AC_Droop_four_Inverters';
simStopTime  = 15;   % load change at t=6s needs the full 15s window to settle
agentFile    = 'trained_fault_agent.mat';   % separate from the other scenario

load_system(modelName);
set_param(modelName, 'FastRestart', 'off');   % avoid the crash issue seen before

%% 1. Logging setup (safe to re-run; only adds blocks if missing)
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

%% 2. Action / observation spaces (identical to the other scenario)
actInfo = rlNumericSpec([3 1], ...
    'LowerLimit', [0.5;  0.5e-4; 2.5], ...
    'UpperLimit', [2.0;  2.0e-4; 10.0]);
actInfo.Name = 'consensus_gains';

obsInfo = rlNumericSpec([4 1], 'LowerLimit', 0, 'UpperLimit', 5);
obsInfo.Name = 'freq_errors';

resetFcnHandle = @() deal(zeros(4,1), struct());
stepFcnHandle  = @(Action, LoggedSignals) stepFcn(Action, LoggedSignals, modelName, simStopTime);

env = rlFunctionEnv(obsInfo, actInfo, stepFcnHandle, resetFcnHandle);

%% 3. Actor and critic networks (identical architecture to the other scenario)
obsDim = obsInfo.Dimension(1);
actDim = actInfo.Dimension(1);

actorNet = [
    featureInputLayer(obsDim, 'Normalization','none','Name','obs')
    fullyConnectedLayer(64,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(64,'Name','fc2')
    reluLayer('Name','relu2')
    fullyConnectedLayer(actDim,'Name','fc_out')
    tanhLayer('Name','tanh_out')
    scalingLayer('Name','scale_out', ...
        'Scale', (actInfo.UpperLimit - actInfo.LowerLimit)/2, ...
        'Bias',  (actInfo.UpperLimit + actInfo.LowerLimit)/2)
    ];
actor = rlContinuousDeterministicActor(actorNet, obsInfo, actInfo);

obsPath = featureInputLayer(obsDim,'Normalization','none','Name','obs');
actPath = featureInputLayer(actDim,'Normalization','none','Name','act');
commonPath = [
    concatenationLayer(1,2,'Name','concat')
    fullyConnectedLayer(64,'Name','cfc1')
    reluLayer('Name','crelu1')
    fullyConnectedLayer(64,'Name','cfc2')
    reluLayer('Name','crelu2')
    fullyConnectedLayer(1,'Name','q_out')
    ];
criticNet = layerGraph(obsPath);
criticNet = addLayers(criticNet, actPath);
criticNet = addLayers(criticNet, commonPath);
criticNet = connectLayers(criticNet, 'obs', 'concat/in1');
criticNet = connectLayers(criticNet, 'act', 'concat/in2');
critic = rlQValueFunction(criticNet, obsInfo, actInfo, ...
    'ObservationInputNames','obs', 'ActionInputNames','act');

%% 4. DDPG agent -- noise decay included from the start this time
agentOpts = rlDDPGAgentOptions(...
    'SampleTime', 1, ...
    'ExperienceBufferLength', 1e4, ...
    'MiniBatchSize', 32);
agentOpts.NoiseOptions.StandardDeviation = 0.2*ones(actDim,1);
agentOpts.NoiseOptions.StandardDeviationDecayRate = 1e-2;
agentOpts.NoiseOptions.StandardDeviationMin = 0.02*ones(actDim,1);
agentOpts.ActorOptimizerOptions.LearnRate  = 1e-3;
agentOpts.CriticOptimizerOptions.LearnRate = 1e-3;

agent = rlDDPGAgent(actor, critic, agentOpts);

%% 5. Train in a short batch (learned from experience: don't run 200
%     episodes unattended in one sitting)
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
fprintf('Training complete. Agent saved to %s\n', agentFile);

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

    Simulink.sdi.clear;   % prevent memory buildup across many sim() calls
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
