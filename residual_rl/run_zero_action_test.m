function report = run_zero_action_test(c)
if nargin<1, c=residual_config(); end
% Original vs exact-original generated copy; corrected-disabled vs corrected-zero.
assert(strcmp(residual_hash(c.source),c.sourceSHA256));
s=residual_scenario(c,'nominal',c.validationSeeds(1));
[~,original]=fileparts(c.source); assert(~bdIsLoaded(original),'Close original model first.');
load_system(c.source); cleanup=onCleanup(@() close_system(original,0));
co=c; co.controllerVariant='original'; verify_signal_map(original,co);
[x,~]=tap_model_measurements(original,co);
log=[original '/ZeroTestLog']; add_block('simulink/Sinks/To Workspace',log, ...
 'VariableName','zero_test_x','SaveFormat','Timeseries','SampleTime',num2str(c.Ts,17), ...
 'MaxDataPoints','inf');
a=get_param(x,'PortHandles'); b=get_param(log,'PortHandles'); add_line(original,a.Outport(1),b.Inport(1));
set_param(original,'Solver',c.solver,'FixedStep',num2str(c.solverStep,17));
set_param(original,'SimulationCommand','update');
out=sim(residual_reset(Simulink.SimulationInput(original),co,s));
[t,baseline]=residual_series(out,'zero_test_x',20); clear cleanup
variants={'original','original','corrected','corrected'};
modes={'disabled','zero','disabled','zero'}; traces=cell(4,1);
for k=1:4
 cc=c; cc.controllerVariant=variants{k}; model=build_residual_model(modes{k},cc);
 load_system(fullfile(cc.output,[model '.slx'])); cleanup=onCleanup(@() close_system(model,0));
 set_param(model,'SimulationCommand','update');
 out=sim(residual_reset(Simulink.SimulationInput(model),cc,s));
 [time,values]=residual_series(out,'residual_x',20);
 [~,u]=residual_series(out,'residual_u',8); assert(all(u==0,'all'));
 assert(time(end)>=c.stopTime-c.Ts); traces{k}=interp1(time,values,t,'linear');
 clear cleanup
end
pairs={baseline,traces{1};traces{1},traces{2};traces{3},traces{4}};
labels={'original_vs_original_disabled','original_disabled_vs_zero','corrected_disabled_vs_zero'};
for k=1:3
 a=pairs{k,1}; b=pairs{k,2}; delta=a-b;
 report(k)=struct('comparison',labels{k},'maxAbsByChannel',max(abs(delta),[],1), ...
  'rmsByChannel',sqrt(mean(delta.^2,1)),'passed', ...
  all(abs(delta)<=c.equivalenceAbsTol+c.equivalenceRelTol*abs(a),'all')); %#ok<AGROW>
end
if ~isfolder(fullfile(c.results,'logs')), mkdir(fullfile(c.results,'logs')); end
save(fullfile(c.results,'logs','zero_action_equivalence.mat'),'report','c','s');
assert(all([report.passed]),'Zero-action equivalence failed; see results/logs/zero_action_equivalence.mat');
assert(strcmp(residual_hash(c.source),c.sourceSHA256));
end
