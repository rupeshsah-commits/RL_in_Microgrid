% Two episodes only; prerequisites and validation must pass first.
projectRoot=fileparts(mfilename('fullpath')); addpath(fullfile(projectRoot,'residual_rl'));
c=residual_config();
require_validation(c);
smokeAgentFile=train_residual('smoke',c);
fprintf('Smoke checkpoint: %s\nNext: review config before RUN_TRAINING.\n',smokeAgentFile);
