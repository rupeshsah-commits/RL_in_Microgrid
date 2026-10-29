% Evaluates the latest best training-reward checkpoint; no claim it is best on test data.
projectRoot=fileparts(mfilename('fullpath')); addpath(fullfile(projectRoot,'residual_rl'));
c=residual_config(); selectedAgent=select_best_agent(c);
comparison=run_baseline_comparison(selectedAgent,c);
