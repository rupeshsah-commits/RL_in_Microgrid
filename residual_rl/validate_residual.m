function report = validate_residual(c)
if nargin<1, c=residual_config(); end
validate_config(c);
unit=runtests(fullfile(c.root,'residual_rl','tests','test_residual.m')); assertSuccess(unit);
report.signature=residual_signature(c); report.unitTests=unit; report.zero=run_zero_action_test(c);
model=build_residual_model('probe',c); load_system(fullfile(c.output,[model '.slx']));
cleanup=onCleanup(@() close_system(model,0));
set_param(model,'SimulationCommand','update');
s=residual_scenario(c,'nominal',c.validationSeeds(1));
out=sim(residual_reset(Simulink.SimulationInput(model),c,s));
m=residual_metrics(out,c,s); assert(m.complete && ~m.terminated);
doneLog=out.get('residual_done'); assert(islogical(doneLog.Data));
[~,u]=residual_series(out,'residual_u',8);
assert(any(abs(u)>0,'all'),'Nonzero probe did not reach the command summing points.');
if c.safetyEnabled
 assert(all(abs(diff(u))<=c.slew.'*c.Ts+1e-9,'all'));
end
report.probe=m; clear cleanup
rng(c.validationSeeds(1),'twister'); agent=residual_agent(c);
[env,model]=create_residual_environment(agent,c); cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
report.compiled=check_compiled_interface(model,c); validateEnvironment(env);
report.environment='PASS'; report.runtime='PASS for explicitly executed validation only';
assert(strcmp(residual_hash(c.source),c.sourceSHA256));
if ~isfolder(fullfile(c.results,'logs')), mkdir(fullfile(c.results,'logs')); end
save(fullfile(c.results,'logs','validation.mat'),'report');
end
