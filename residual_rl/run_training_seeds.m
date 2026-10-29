function files = run_training_seeds(c)
% Explicit full multi-policy-seed experiment; no automatic setup invocation.
if nargin<1, c=residual_config(); end
files=cell(numel(c.trainSeeds),1); reports=cell(size(files));
for i=1:numel(c.trainSeeds)
 cc=c; cc.seed=c.trainSeeds(i); files{i}=train_residual('full',cc);
 files{i}=fullfile(fileparts(files{i}),'best_agent.mat');
 reports{i}=evaluate_residual(files{i},cc);
end
aggregate_policy_seeds(reports,c);
end
