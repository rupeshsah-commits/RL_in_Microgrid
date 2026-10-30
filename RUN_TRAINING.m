% Deliberate opt-in; edit the explicit flags below after reviewing study bases.
projectRoot=fileparts(mfilename('fullpath')); addpath(fullfile(projectRoot,'residual_rl'));
c=residual_config();
% c.allowFullTraining=true;
% c.ratingsConfirmed=true; % only after confirming/replacing Prated and Qrated
assert(c.allowFullTraining && c.ratingsConfirmed, ...
 'Review config, confirm normalization ratings and explicitly enable full training.');
require_validation(c);
trainedAgentFile=train_residual('full',c);
fprintf('Full checkpoint: %s\nNext command: RUN_EVALUATION\n',trainedAgentFile);
