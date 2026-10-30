function plan = run_ablations(mode,c)
% Plans default to no training. Every variant requires retraining its own policy.
if nargin<1, mode='plan'; end
if nargin<2, c=residual_config(); end
names={'full','no_voltage','no_sharing','no_action_rate','no_slew_smoothing','fixed_weights'};
plan=struct([]);
for k=1:numel(names)
 cc=c;
 switch names{k}
  case 'no_voltage', cc.rewardWeights(2)=0;
  case 'no_sharing', cc.rewardWeights(3:4)=0;
  case 'no_action_rate', cc.rewardWeights(6)=0;
  case 'no_slew_smoothing', cc.safetyEnabled=false;
  case 'fixed_weights', cc.adaptiveWeights=false;
 end
 % The hard amplitude, finite-value fallback and unsafe-state gate are NEVER removed.
 entry=struct('variant',names{k},'signature',residual_signature(cc),'config',cc,'agentFile','');
 if strcmp(mode,'train')
  validate_residual(cc);
  entry.agentFile=train_residual('full',cc);
  entry.agentFile=fullfile(fileparts(entry.agentFile),'best_agent.mat');
  run_baseline_comparison(entry.agentFile,cc);
 else
  assert(strcmp(mode,'plan'),'Use plan or train.');
 end
 plan=[plan;entry]; %#ok<AGROW>
end
if ~isfolder(fullfile(c.results,'tables')), mkdir(fullfile(c.results,'tables')); end
save(fullfile(c.results,'tables','ablation_plan.mat'),'plan');
end
