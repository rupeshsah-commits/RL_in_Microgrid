function tests=test_model_runtime
% Explicit additional model tests; they are not executed by static checkers.
tests=functiontests(localfunctions);
end
function testBuilderIdempotence(t)
c=residual_config(); before=residual_hash(c.source);
a=build_residual_model('zero',c); load_system(fullfile(c.output,[a '.slx']));
first=numel(find_system(a,'LookUnderMasks','all','Type','Block')); close_system(a,0);
b=build_residual_model('zero',c); load_system(fullfile(c.output,[b '.slx']));
cleanup=onCleanup(@() close_system(b,0)); %#ok<NASGU>
verifyEqual(t,numel(find_system(b,'LookUnderMasks','all','Type','Block')),first);
verifyEqual(t,residual_hash(c.source),before);
end
function testEnvironmentInterface(t)
c=residual_config(); agent=residual_agent(c); [env,model]=create_residual_environment(agent,c);
cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
validateEnvironment(env); verifyEqual(t,getObservationInfo(env).Dimension,[42 1]);
verifyEqual(t,getActionInfo(env).Dimension,[8 1]);
end
function testZeroEquivalenceAndFiniteSimulation(t)
report=run_zero_action_test(); verifyTrue(t,all([report.passed]));
end

function testResetOverridesStoredWithoutSimulation(t)
c=residual_config(); model=c.sourceName;
assert(~bdIsLoaded(model),'Close the original model before this test.');
load_system(c.source); cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
s=residual_scenario(c,'reactive',c.validationSeeds(1));
s.initialBreaker='closed'; s.switchTimes=6.5; s.Lscale=1.03;
in=residual_reset(Simulink.SimulationInput(model),c,s);
expected={ [model '/Load 5'],'ActivePower',num2str(s.loadP,17); ...
 [model '/Load 5'],'InductivePower',num2str(s.loadQ,17); ...
 [model '/Load 5'],'CapacitivePower','0'; ...
 [model '/Three-Phase Breaker1'],'InitialState','closed'; ...
 [model '/Three-Phase Breaker1'],'SwitchTimes',mat2str(s.switchTimes,17)};
for i=1:4
 expected(end+1,:)={sprintf('%s/DG%d/L1',model,i),'Inductance',num2str(4e-3*s.Lscale,17)}; %#ok<AGROW>
end
parameters=in.BlockParameters;
verifyEqual(t,numel(parameters),size(expected,1));
for i=1:size(expected,1)
 matches=false(size(parameters));
 for j=1:numel(parameters)
  path=parameters(j).BlockPath;
  if isa(path,'Simulink.BlockPath'), path=getBlock(path,1); end
  matches(j)=strcmp(path,expected{i,1}) && strcmp(parameters(j).Name,expected{i,2}) ...
   && strcmp(parameters(j).Value,expected{i,3});
 end
 verifyEqual(t,nnz(matches),1);
end
verifyEqual(t,residual_hash(c.source),c.sourceSHA256);
end
