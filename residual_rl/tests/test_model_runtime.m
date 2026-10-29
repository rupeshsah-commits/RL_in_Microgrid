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
