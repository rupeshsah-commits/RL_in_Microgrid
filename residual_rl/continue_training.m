function agentFile = continue_training(checkpoint,c)
% Explicit resume; no implicit discovery of a possibly incompatible old agent.
if nargin<2, c=residual_config(); end
assert(isfile(checkpoint),'Checkpoint not found.');
agentFile=train_residual('full',c,checkpoint);
end
