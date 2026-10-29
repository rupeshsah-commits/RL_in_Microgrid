function validate_residual()
% Required local gate: unit tests, model update, zero equivalence, bounded probe.
c=residual_config();
results=runtests(fullfile(c.root,'residual_rl','tests')); assertSuccess(results);
models={build_residual_model('zero',c),build_residual_model('probe',c)};
for k=1:2
    model=models{k}; load_system(fullfile(c.output,[model '.slx']));
    cleanup=onCleanup(@() close_system(model,0));
    set_param(model,'SimulationCommand','update');
    out=sim(residual_reset(Simulink.SimulationInput(model),c,1));
    residual_metrics(out,c);
    u=out.get('residual_u'); a=squeeze(u.Data);
    if size(a,1)~=numel(u.Time), a=a.'; end
    assert(all(abs(a)<=c.limits.'+1e-10,'all'));
    assert(all(abs(diff(a))<=c.slew.'*c.Ts+1e-10,'all'));
    if k==1
        assert(all(a==0,'all')); zero=out.get('residual_x');
    else
        assert(any(abs(a)>0,'all'),'Probe never reached the plant.');
    end
    clear cleanup
end
% Original baseline: in-memory logging only, then close without saving.
[~,original]=fileparts(c.source);
assert(~bdIsLoaded(original),'Close the original model first to preserve unsaved work.');
load_system(c.source);
cleanup=onCleanup(@() close_system(original,0)); %#ok<NASGU>
add_block('simulink/Signal Routing/Mux',[original '/ValidationMux'],'Inputs','8');
for i=1:8
    if i<=4, tag=sprintf('w%d',i); else, tag=sprintf('Vd%d',i-4); end
    name=['Validation_' tag];
    add_block('simulink/Signal Routing/From',[original '/' name],'GotoTag',tag);
    add_line(original,[name '/1'],sprintf('ValidationMux/%d',i));
end
add_block('simulink/Sinks/To Workspace',[original '/ValidationLog'], ...
    'VariableName','validation_x','SaveFormat','Timeseries','SampleTime',num2str(c.Ts), ...
    'MaxDataPoints','inf');
add_line(original,'ValidationMux/1','ValidationLog/1');
in=residual_reset(Simulink.SimulationInput(original),c,1);
in=in.setModelParameter('ReturnWorkspaceOutputs','on');
out=sim(in); baseline=out.get('validation_x');
y=interp1(baseline.Time,squeeze(baseline.Data),zero.Time,'linear');
assert(all(abs(y-squeeze(zero.Data))<1e-5+1e-7*abs(y),'all'), ...
    'Zero residual does not reproduce original baseline.');
clear cleanup
[residualAgent,obsInfo,actInfo]=residual_agent(c);
assignin('base','residualAgent',residualAgent);
model=build_residual_model('agent',c); load_system(fullfile(c.output,[model '.slx']));
cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
set_param(model,'SimulationCommand','update');
env=rlSimulinkEnv(model,[model '/ResidualAgent'],obsInfo,actInfo);
env.ResetFcn=@(in) residual_reset(in,c,1);
validateEnvironment(env);
fprintf('Local simulation validation passed; training performance remains separate.\n');
end
