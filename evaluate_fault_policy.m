%% evaluate_fault_policy.m
% Gets the trained agent's actual, noise-free recommended gains (not a
% noisy exploratory sample from training), applies them, and runs one
% clean validation simulation for a fair before/after comparison.

clear; clc;

modelName = 'Fault_RLready_AC_Droop_four_Inverters';
agentFile = 'trained_fault_agent.mat';

loaded = load(agentFile, 'agent');
agent = loaded.agent;

%% 1. Get the agent's deterministic action (no exploration noise)
% Observation at the start of an episode is always zeros(4,1) in this
% environment's resetFcn, so this reproduces exactly what the agent
% would recommend as its "best guess" with no randomness.
obs0 = {zeros(4,1)};
actionCell = getAction(agent, obs0);
action = actionCell{1};

k_couple = action(1);
k_power  = action(2);
k_corr   = action(3);

fprintf('Agent''s learned (noise-free) recommendation:\n');
fprintf('  k_couple = %.4f  (baseline was 1)\n', k_couple);
fprintf('  k_power  = %.6f  (baseline was 1e-4)\n', k_power);
fprintf('  k_corr   = %.4f  (baseline was 5)\n', k_corr);

%% 2. Apply these gains and run one clean validation simulation
assignin('base', 'k_couple', k_couple);
assignin('base', 'k_power',  k_power);
assignin('base', 'k_corr',   k_corr);

load_system(modelName);
set_param(modelName, 'StopTime', '15');
simOut = sim(modelName);

fprintf('\nSimulation complete. Open Scope15 in the model to view the result,\n');
fprintf('or compare against your baseline scope using the same k values above.\n');
