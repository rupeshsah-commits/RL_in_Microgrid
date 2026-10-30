function signature = residual_signature(c)
% Bind a policy to control/reward/observation semantics, excluding machine paths.
p=residual_parameters(c); p.controllerVariant=c.controllerVariant; p.source=c.sourceSHA256;
p.stopTime=c.stopTime; p.solver=c.solver; p.enableResidual=c.enableResidual;
p.mp=c.mp; p.nq=c.nq; p.plantTs=c.plantTs; p.solverStep=c.solverStep;
files={'build_residual_model','residual_agent','residual_observation','residual_reward', ...
 'residual_safety','conventional_voltage_rate','model_signal_map','residual_parameters', ...
 'residual_reset','residual_scenario','residual_priorities','residual_signature'};
for k=1:numel(files)
 p.implementation.(files{k})=residual_hash(fullfile(c.root,'residual_rl',[files{k} '.m']));
end
text=jsonencode(p); md=java.security.MessageDigest.getInstance('SHA-256');
md.update(uint8(text)); signature=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
