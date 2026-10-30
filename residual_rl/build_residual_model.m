function model = build_residual_model(mode,c)
% Idempotent rebuild of generated copies. Original source is never saved.
if nargin<1, mode='agent'; end
if nargin<2, c=residual_config(); end
validate_config(c);
assert(ismember(mode,{'agent','zero','disabled','probe'}),'Unknown builder mode.');
assert(strcmp(residual_hash(c.source),c.sourceSHA256),'Original SLX checksum mismatch.');
if ~isfolder(c.output), mkdir(c.output); end
model=c.model;
if ~strcmp(c.controllerVariant,'corrected'), model=[model '_' c.controllerVariant]; end
if ~strcmp(mode,'agent'), model=[model '_' mode]; end
dest=fullfile(c.output,[model '.slx']);
assert(~bdIsLoaded(model),'Close generated model first; unsaved edits are preserved.');
assert(~strcmp(dest,c.source)); copyfile(c.source,dest,'f'); load_system(dest);
cleanup=onCleanup(@() close_system(model,0)); %#ok<NASGU>
map=verify_signal_map(model,c);
Simulink.fileGenControl('set','CacheFolder',fullfile(c.output,'cache'), ...
 'CodeGenFolder',fullfile(c.output,'codegen'),'createDir',true);
% Explicit, conservative step matches archive powergui (2 microseconds).
set_param(model,'StopTime',num2str(c.stopTime),'FastRestart','off', ...
 'Solver',c.solver,'FixedStep',num2str(c.solverStep,17),'ReturnWorkspaceOutputs','on');
w=get_param(model,'ModelWorkspace'); assignin(w,'residualCfg',c);
s=residual_scenario(c,'nominal',c.validationSeeds(1));
assignin(w,'residualScenario',s); assignin(w,'residualNoise',make_residual_noise(c,s));
assignin(w,'residualEnabled',double(c.enableResidual && ~strcmp(mode,'disabled')));
[xPath,xiPath]=tap_model_measurements(model,c);
if ~strcmp(c.controllerVariant,'original'), correct_conventional(model,map,c,xPath); end
% Add after the complete conventional command at each outer reference output.
% Branches of command outputs (including omega logging) now observe final command.
for i=1:4
 d=map.dg{i};
 sources={map.omegaInjection{i},map.voltageInjection{i}};
 for j=1:2
  ph=get_param(sources{j},'PortHandles'); line=get_param(ph.Outport(1),'Line');
  destinations=get_param(line,'DstPortHandle');
  assert(~isempty(destinations) && all(destinations~=-1),'Missing command destinations.');
  delete_line(line);
  a=sprintf('%s/ResidualCommandSum%d',d,j);
  add_block('simulink/Math Operations/Sum',a,'Inputs','++');
  input=sprintf('%s/ResidualInput%d',d,j);
  add_block('built-in/Inport',input,'Port',num2str(j+2));
  wire(d,sources{j},1,a,1); wire(d,input,1,a,2);
  out=get_param(a,'PortHandles');
  for h=destinations(:).', add_line(d,out.Outport(1),h,'autorouting','on'); end
 end
end
% A single, visible interface isolates policy, reward and actuator safety.
iface=[model '/' c.interface];
add_block('simulink/Ports & Subsystems/Subsystem',iface,'Position',[2600 50 2950 450]);
Simulink.SubSystem.deleteContents(iface);
add_block('built-in/Inport',[iface '/TrueMeasurements'],'Port','1');
add_block('built-in/Inport',[iface '/SecondaryStates'],'Port','2');
add_block('built-in/Outport',[iface '/PhysicalResidual'],'Port','1');
add_block('simulink/Discrete/Zero-Order Hold',[iface '/Sample'],'SampleTime','residualCfg.Ts');
wire(iface,[iface '/TrueMeasurements'],1,[iface '/Sample'],1);
add_block('simulink/Discrete/Zero-Order Hold',[iface '/StateSample'],'SampleTime','residualCfg.Ts');
wire(iface,[iface '/SecondaryStates'],1,[iface '/StateSample'],1);
add_block('simulink/Sources/Digital Clock',[iface '/Clock'],'SampleTime','residualCfg.Ts');
add_block('simulink/Sources/From Workspace',[iface '/Noise'], ...
 'VariableName','residualNoise','Interpolate','off');
add_block('simulink/Math Operations/Sum',[iface '/NoisyMeasurements'],'Inputs','++');
wire(iface,[iface '/Sample'],1,[iface '/NoisyMeasurements'],1);
wire(iface,[iface '/Noise'],1,[iface '/NoisyMeasurements'],2);
add_block('simulink/Discrete/Delay',[iface '/CommunicationDelay'], ...
 'DelayLength','residualScenario.delaySteps','InitialCondition', ...
 mat2str([repmat(c.omega0,4,1);repmat(c.v0,4,1);zeros(12,1)],17));
wire(iface,[iface '/NoisyMeasurements'],1,[iface '/CommunicationDelay'],1);
add_block('simulink/Discrete/Unit Delay',[iface '/Applied'], ...
 'InitialCondition','zeros(8,1)','SampleTime','residualCfg.Ts');
add_block('simulink/Discrete/Unit Delay',[iface '/Previous'], ...
 'InitialCondition','zeros(8,1)','SampleTime','residualCfg.Ts');
wire(iface,[iface '/Applied'],1,[iface '/Previous'],1);
add_block('simulink/Sources/Constant',[iface '/Enable'],'Value','residualEnabled');
p=literal(residual_parameters(c));
chart(iface,'Observation',sprintf(['function obs=f(x,u,xi)\np=%s;\n' ...
 'obs=residual_observation(x,u,xi,p);\nend'],p));
wire(iface,[iface '/CommunicationDelay'],1,[iface '/Observation'],1);
wire(iface,[iface '/Applied'],1,[iface '/Observation'],2);
wire(iface,[iface '/StateSample'],1,[iface '/Observation'],3);
chart(iface,'Reward',sprintf(['function [r,done,parts]=f(x,u,old,t,a)\np=%s;\n' ...
 '[r,done,parts]=residual_reward(x,u,old,t,p,a);\nend'],p));
wire(iface,[iface '/Sample'],1,[iface '/Reward'],1);
wire(iface,[iface '/Applied'],1,[iface '/Reward'],2);
wire(iface,[iface '/Previous'],1,[iface '/Reward'],3);
wire(iface,[iface '/Clock'],1,[iface '/Reward'],4);
chart(iface,'Safety',sprintf(['function [u,hit]=f(a,old,x,t,enabled)\np=%s;\n' ...
 '[u,hit]=residual_safety(a,old,x,t,enabled,p);\nend'],p));
wire(iface,[iface '/Applied'],1,[iface '/Safety'],2);
wire(iface,[iface '/Sample'],1,[iface '/Safety'],3);
wire(iface,[iface '/Clock'],1,[iface '/Safety'],4);
wire(iface,[iface '/Enable'],1,[iface '/Safety'],5);
wire(iface,[iface '/Safety'],1,[iface '/Applied'],1);
placeholder=false;
if strcmp(mode,'agent') && evalin('base','exist(''residualAgent'',''var'')')
 load_system('rl_lib');
 add_block('rl_lib/RL Agent',[iface '/Agent'],'Agent','residualAgent');
 wire(iface,[iface '/Observation'],1,[iface '/Agent'],1);
 wire(iface,[iface '/Reward'],1,[iface '/Agent'],2);
 wire(iface,[iface '/Reward'],2,[iface '/Agent'],3);
else
 value='zeros(8,1)'; if strcmp(mode,'probe'), value='0.1*ones(8,1)'; end
 add_block('simulink/Sources/Constant',[iface '/Agent'],'Value',value, ...
   'SampleTime','residualCfg.Ts');
 placeholder=strcmp(mode,'agent');
end
add_block('simulink/Discrete/Unit Delay',[iface '/RawPrevious'], ...
 'InitialCondition','zeros(8,1)','SampleTime','residualCfg.Ts');
wire(iface,[iface '/Agent'],1,[iface '/RawPrevious'],1);
wire(iface,[iface '/RawPrevious'],1,[iface '/Reward'],5);
wire(iface,[iface '/Agent'],1,[iface '/Safety'],1);
% Independent enable/finite-memory bypass. No current measurement or agent
% direct feedthrough here: the validated Unit Delay is the causality boundary.
chart(iface,'Bypass',sprintf(['function u=f(memory,enable)\n' ...
 'u=memory;\nif ~enable || any(~isfinite(memory)), u=zeros(8,1); end\nend']));
wire(iface,[iface '/Applied'],1,[iface '/Bypass'],1);
wire(iface,[iface '/Enable'],1,[iface '/Bypass'],2);
wire(iface,[iface '/Bypass'],1,[iface '/PhysicalResidual'],1);
wire(model,xPath,1,iface,1); wire(model,xiPath,1,iface,2);
add_block('simulink/Signal Routing/Demux',[model '/ResidualSplit'],'Outputs','8');
wire(model,iface,1,[model '/ResidualSplit'],1);
for i=1:4
 wire(model,[model '/ResidualSplit'],i,map.dg{i},3);
 wire(model,[model '/ResidualSplit'],i+4,map.dg{i},4);
end
sources={'Sample','CommunicationDelay','Bypass','Previous','Agent','Reward','Reward','Reward','Safety','StateSample'};
ports=[1 1 1 1 1 1 2 3 2 1];
vars={'residual_x','residual_x_agent','residual_u','residual_previous','residual_command', ...
 'residual_reward_log','residual_done','residual_components','residual_intervention','residual_xi'};
for k=1:numel(vars), logger(iface,sources{k},ports(k),vars{k},c.Ts); end
set_param(model,'UserData',struct('mode',mode,'controllerVariant',c.controllerVariant, ...
 'agentPlaceholder',placeholder,'runtimeValidated',false),'UserDataPersistent','on');
Simulink.BlockDiagram.arrangeSystem(iface);
save_system(model,dest);
buildReport=struct('model',model,'sourceSHA256',c.sourceSHA256, ...
 'generatedSHA256',residual_hash(dest),'builtBy','MATLAB save_system','compiled',false);
fid=fopen(fullfile(c.output,[model '_build.json']),'w');
assert(fid>=0); fprintf(fid,'%s\n',jsonencode(buildReport)); fclose(fid);
assert(strcmp(residual_hash(c.source),c.sourceSHA256),'Source changed unexpectedly.');
end
function correct_conventional(model,map,c,x)
p=literal(residual_parameters(c));
chart(model,'ConventionalVoltageRate',sprintf(['function rate=f(x,raw)\np=%s;\n' ...
 'rate=conventional_voltage_rate(x,raw,p);\nend'],p));
add_block('simulink/Signal Routing/Mux',[model '/VoltageRawStates'],'Inputs','4');
add_block('simulink/Signal Routing/Demux',[model '/VoltageRates'],'Outputs','4');
wire(model,x,1,[model '/ConventionalVoltageRate'],1);
wire(model,[model '/VoltageRawStates'],1,[model '/ConventionalVoltageRate'],2);
wire(model,[model '/ConventionalVoltageRate'],1,[model '/VoltageRates'],1);
for i=1:4
 set_param([map.dg{i} '/Constant5'],'Value',num2str(c.omega0,17));
 if i==1
  set_param([map.dg{i} '/Step'],'Before',num2str(c.v0,17),'After',num2str(c.v0,17));
 else
  set_param([map.dg{i} '/Constant1'],'Value',num2str(c.v0,17));
 end
 set_param([map.dg{i} '/Gain3'],'Gain',num2str(c.mp(i),17));
 set_param([map.dg{i} '/Gain4'],'Gain',num2str(c.nq(i),17));
 v=[model '/' map.voltageIntegrators{i}]; w=[model '/' map.frequencyIntegrators{i}];
 wire(model,v,1,[model '/VoltageRawStates'],i);
 ph=get_param(v,'PortHandles'); delete_line(get_param(ph.Inport(1),'Line'));
 wire(model,[model '/VoltageRates'],i,v,1);
 for group=1:2
  paths={w,v}; bounds=[c.secondaryWLimit c.secondaryVLimit]/c.secondaryGain;
  set_param(paths{group},'LimitOutput','on','UpperSaturationLimit',num2str(bounds(group),17), ...
   'LowerSaturationLimit',num2str(-bounds(group),17));
 end
 % Preserve original frequency topology, normalize unequal-rated P before differences.
 rt=sfroot; ch=rt.find('-isa','Stateflow.EMChart','Path',map.chart{i});
 assert(numel(ch)==1,'Secondary chart not found.');
 code=ch.Script;
 code=strrep(code,'(1e-4)',sprintf('(%.17g)',c.kPshare/c.Pbase));
 code=strrep(code,'2*pi*60',sprintf('%.17g',c.omega0));
 pos=find(code==newline,1);
 % Some charts do not have all four P inputs: only scale those present.
 inputs=regexp(code(1:pos-1),'P[1-4]','match'); prefix='';
 for j=1:numel(inputs)
  idx=str2double(inputs{j}(2));
  prefix=[prefix sprintf('%s=%s*%.17g;\n',inputs{j},inputs{j},c.Pbase/c.Prated(idx))]; %#ok<AGROW>
 end
 ch.Script=[code(1:pos) prefix code(pos+1:end)];
 if strcmp(c.controllerVariant,'primary')
  set_param(map.omegaGain{i},'Gain','0'); set_param(map.voltageGain{i},'Gain','0');
 end
end
end
function chart(sys,name,script)
path=[sys '/' name]; add_block('simulink/User-Defined Functions/MATLAB Function',path);
rt=sfroot; ch=rt.find('-isa','Stateflow.EMChart','Path',path); ch.Script=script;
end
function text=literal(p)
names=fieldnames(p); text='struct(';
for k=1:numel(names)
 if k>1, text=[text ',']; end %#ok<AGROW>
 text=[text char(39) names{k} char(39) ',' mat2str(p.(names{k}),17)]; %#ok<AGROW>
end
text=[text ')'];
end
function wire(sys,src,sp,dst,dp)
a=get_param(src,'PortHandles'); b=get_param(dst,'PortHandles');
add_line(sys,a.Outport(sp),b.Inport(dp),'autorouting','on');
end
function logger(sys,src,port,name,Ts)
path=[sys '/Log_' name];
add_block('simulink/Sinks/To Workspace',path,'VariableName',name, ...
 'SaveFormat','Timeseries','SampleTime',num2str(Ts,17),'MaxDataPoints','inf');
wire(sys,[sys '/' src],port,path,1);
end
