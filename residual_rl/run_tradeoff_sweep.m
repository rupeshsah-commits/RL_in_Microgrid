function plan = run_tradeoff_sweep(mode,c)
if nargin<1, mode='plan'; end
if nargin<2, c=residual_config(); end
weights=[1 1 0.2;2 1 0.2;1 2 0.2;1 1 0.5]; plan=cell(size(weights,1),1);
for i=1:size(weights,1)
 cc=c; cc.rewardWeights(1:4)=[weights(i,1);weights(i,2);weights(i,3);weights(i,3)];
 entry=struct('weights',cc.rewardWeights,'signature',residual_signature(cc),'agentFile','');
 if strcmp(mode,'train')
  validate_residual(cc);
  entry.agentFile=train_residual('full',cc);
  entry.agentFile=fullfile(fileparts(entry.agentFile),'best_agent.mat'); evaluate_residual(entry.agentFile,cc);
 else
  assert(strcmp(mode,'plan'));
 end
 plan{i}=entry;
end
if ~isfolder(fullfile(c.results,'tables')), mkdir(fullfile(c.results,'tables')); end
save(fullfile(c.results,'tables','tradeoff_plan.mat'),'plan');
end
