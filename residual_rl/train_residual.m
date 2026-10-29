function agentFile = train_residual(mode,c,checkpoint)
% Default is a two-episode smoke test, never an automatic full training job.
if nargin<1, mode='smoke'; end
if nargin<2, c=residual_config(); end
if nargin<3, checkpoint=''; end
assert(ismember(mode,{'smoke','full'})); validate_config(c);
if strcmp(mode,'full')
 assert(c.allowFullTraining,'Set allowFullTraining=true deliberately to start full training.');
 assert(c.ratingsConfirmed,'Confirm/replace study normalization ratings before full training.');
 require_validation(c);
end
rng(c.seed,'twister');
if isempty(checkpoint)
 residualAgent=residual_agent(c);
else
 saved=load(checkpoint);
 if isfield(saved,'residualAgent'), residualAgent=saved.residualAgent;
 elseif isfield(saved,'agent'), residualAgent=saved.agent;
 elseif isfield(saved,'saved_agent'), residualAgent=saved.saved_agent;
 else, error('Checkpoint contains no supported agent field.'); end
 if isfield(saved,'rngState'), rng(saved.rngState); end
 if ~isfield(saved,'signature')
  metaPath=fullfile(fileparts(fileparts(checkpoint)),'run_config.mat');
  assert(isfile(metaPath),'Checkpoint metadata missing; cannot safely resume.');
  meta=load(metaPath,'signature'); saved.signature=meta.signature;
 end
 assert(strcmp(saved.signature,residual_signature(c)),'Checkpoint configuration mismatch.');
 % Prevent silently mixing configurations or observation dimensions.
 [obsInfo,~]=residual_specs(c);
 assert(isequal(getObservationInfo(residualAgent).Dimension,obsInfo.Dimension));
end
[env,model]=create_residual_environment(residualAgent,c);
cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
validateEnvironment(env);
runDir=fullfile(c.results,'checkpoints',[mode '_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
mkdir(runDir); c.runDir=runDir;
agentFile=fullfile(runDir,'residual_agent.mat');
signature=residual_signature(c); bestScore=-Inf;
metadata=struct('release',version('-release'),'version',version,'products',ver);
save(fullfile(runDir,'run_config.mat'),'c','signature','metadata');
rngState=rng; trainingStats={}; status='initialized'; %#ok<NASGU>
save(agentFile,'residualAgent','c','rngState','trainingStats','status','signature','-v7.3');
% Replay-buffer saving supports recovery; snapshots can be large and stay ignored.
residualAgent.AgentOptions.InfoToSave.ExperienceBuffer=true;
if strcmp(mode,'smoke')
 episodes=c.smokeEpisodes; stages=c.curriculumStage;
else
 episodes=c.episodes; stages=1:3;
end
try
 for stage=stages
  stageConfig=c; stageConfig.curriculumStage=stage;
  env.ResetFcn=@(in) residual_reset(in,stageConfig);
  for batchStart=1:c.checkpointEvery:episodes
   batchEpisodes=min(c.checkpointEvery,episodes-batchStart+1);
   opts=rlTrainingOptions('MaxEpisodes',batchEpisodes,'MaxStepsPerEpisode',ceil(c.stopTime/c.Ts), ...
    'Verbose',true,'Plots','none','SaveAgentCriteria','EpisodeFrequency', ...
    'SaveAgentValue',c.checkpointEvery,'SaveAgentDirectory', ...
    fullfile(runDir,sprintf('stage%d_batch%d',stage,batchStart)));
   stats=train(residualAgent,env,opts);
   trainingStats{end+1}=stats;
   rngState=rng; status='batch_complete';
   save(agentFile,'residualAgent','c','rngState','trainingStats','status','stage','signature','-v7.3');
   score=mean(stats.EpisodeReward);
   if isfinite(score) && score>bestScore
    bestScore=score;
    save(fullfile(runDir,'best_agent.mat'),'residualAgent','c','rngState', ...
      'trainingStats','status','signature','bestScore','stage','-v7.3');
   end
  end
 end
 status='completed'; rngState=rng;
 save(agentFile,'residualAgent','c','rngState','trainingStats','status','signature','-v7.3');
catch err
 status='interrupted_or_failed'; rngState=rng; failure=getReport(err,'extended'); %#ok<NASGU>
 save(agentFile,'residualAgent','c','rngState','trainingStats','status','failure','signature','-v7.3');
 rethrow(err)
end
fprintf('Agent checkpoint: %s\n',agentFile);
end
