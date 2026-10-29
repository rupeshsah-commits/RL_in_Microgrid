function train_residual()
c = residual_config(); rng(c.seed,'twister');
[residualAgent,obsInfo,actInfo] = residual_agent(c);
model = build_residual_model('agent',c); load_system(fullfile(c.output,[model '.slx']));
cleanup = onCleanup(@() close_system(model,0)); %#ok<NASGU>
assignin('base','residualAgent',residualAgent);
env = rlSimulinkEnv(model,[model '/ResidualAgent'],obsInfo,actInfo);
env.ResetFcn = @(in) residual_reset(in,c);
validateEnvironment(env);
if ~isfolder(c.results), mkdir(c.results); end
runDir = fullfile(c.results,['training_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
mkdir(runDir);
opts = rlTrainingOptions('MaxEpisodes',c.episodes, ...
    'MaxStepsPerEpisode',ceil(c.stopTime/c.Ts),'Plots','none','Verbose',true, ...
    'SaveAgentCriteria','EpisodeFrequency','SaveAgentValue',10, ...
    'SaveAgentDirectory',fullfile(runDir,'checkpoints'));
trainingStats = train(residualAgent,env,opts);
save(fullfile(runDir,'residual_agent.mat'),'residualAgent','trainingStats','c');
fprintf('Saved %s\n',fullfile(runDir,'residual_agent.mat'));
end
