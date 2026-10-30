function in = residual_reset(in,c,s)
if nargin<3, s=residual_scenario(c,'training',randi(2^31-1)); end
assert(s.loadP>0 && isfinite(s.loadP) && isfinite(s.loadQ) && s.loadQ>=0);
assert(isfinite(s.Lscale) && s.Lscale>0 && s.noiseFraction>=0 && isfinite(s.noiseFraction));
assert(s.delaySteps>=0 && s.delaySteps==fix(s.delaySteps) && s.delaySteps<=10);
assert(all(s.switchTimes>c.warmup & s.switchTimes<c.stopTime));
in=in.setModelParameter('StopTime',num2str(c.stopTime),'FastRestart','off', ...
 'LoadInitialState','off','ReturnWorkspaceOutputs','on');
% SimulationInput uses block-path/name/value triples, unlike set_param's pairs.
% One override per call avoids treating a parameter name as the next block path.
loadPath=[in.ModelName '/Load 5'];
in=in.setBlockParameter(loadPath,'ActivePower',num2str(s.loadP,17));
in=in.setBlockParameter(loadPath,'InductivePower',num2str(s.loadQ,17));
in=in.setBlockParameter(loadPath,'CapacitivePower','0');
breakerPath=[in.ModelName '/Three-Phase Breaker1'];
in=in.setBlockParameter(breakerPath,'InitialState',s.initialBreaker);
in=in.setBlockParameter(breakerPath,'SwitchTimes',mat2str(s.switchTimes,17));
for i=1:4
 in=in.setBlockParameter(sprintf('%s/DG%d/L1',in.ModelName,i), ...
  'Inductance',num2str(4e-3*s.Lscale,17));
end
in=in.setVariable('residualScenario',s,'Workspace',in.ModelName);
in=in.setVariable('residualNoise',make_residual_noise(c,s),'Workspace',in.ModelName);
end
