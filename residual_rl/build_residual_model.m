function model = build_residual_model(mode,c)
% Generate separate copies only. Never save edits to the original SLX.
arguments
    mode (1,:) char {mustBeMember(mode,{'agent','zero','probe'})} = 'zero'
    c struct = residual_config()
end
assert(c.Ts>0 && c.stopTime>c.warmup && c.warmup>=0);
assert(isequal(size(c.limits),[8 1]) && all(isfinite(c.limits)) && all(c.limits>0));
assert(isequal(size(c.slew),[8 1]) && all(isfinite(c.slew)) && all(c.slew>0));
assert(isfile(c.source),'Original SLX missing (filename is case-sensitive).');
if ~isfolder(c.output), mkdir(c.output); end
model = ['Residual_Load_Changes_' mode];
dest = fullfile(c.output,[model '.slx']);
assert(~bdIsLoaded(model),'Close generated model before rebuilding.');
assert(~strcmp(c.source,dest));
copyfile(c.source,dest,'f');
load_system(dest);
cleanup = onCleanup(@() close_system(model,0)); %#ok<NASGU>
Simulink.fileGenControl('set','CacheFolder',fullfile(c.output,'cache'), ...
    'CodeGenFolder',fullfile(c.output,'codegen'),'createDir',true);
set_param(model,'StopTime',num2str(c.stopTime),'FastRestart','off', ...
    'ReturnWorkspaceOutputs','on');
% c is stored in generated model workspace, never dependent on base config.
w = get_param(model,'ModelWorkspace'); assignin(w,'residualCfg',c);
p = [c.f0;c.v0;c.fScale;c.vScale;c.tripHz;c.tripVoltagePU;c.warmup;c.Ts; ...
    c.rewardWeights(:);c.terminalPenalty;c.limits];
assignin(w,'residualRewardParameters',p);
% Read actual outgoing port connections rather than assuming line handles.
% Insert directly after secondary Gain / Gain9: residual units rad/s and V.
for i = 1:4
    dg = sprintf('%s/DG%d',model,i);
    for j = 1:2
        names = {'Gain','Gain9'};
        source = [dg '/' names{j}];
        assert(str2double(get_param(source,'Gain')) == 5, ...
            'Unexpected secondary gain: inspect source topology.');
        ph = get_param(source,'PortHandles');
        line = get_param(ph.Outport(1),'Line');
        dst = get_param(line,'DstPortHandle');
        assert(numel(dst)==1,'Unexpected branch at secondary gain.');
        target = get_param(dst,'Parent'); port = get_param(dst,'PortNumber');
        expected = {'Sum2','Sum6'};
        assert(strcmp(get_param(target,'Name'),expected{j}) && port==2, ...
            'Unexpected injection point.');
        delete_line(line);
        sumPath = sprintf('%s/ResidualSum%d',dg,j);
        add_block('simulink/Math Operations/Sum',sumPath,'Inputs','++');
        add_block('simulink/Sources/In1',sprintf('%s/ResidualIn%d',dg,j), ...
            'Port',num2str(j+2));
        add_line(dg,[names{j} '/1'],sprintf('ResidualSum%d/1',j));
        add_line(dg,sprintf('ResidualIn%d/1',j),sprintf('ResidualSum%d/2',j));
        sp = get_param(sumPath,'PortHandles');
        add_line(dg,sp.Outport(1),dst,'autorouting','on');
    end
end
% Centralized measurements in verified root-tag order: w1..w4,Vd1..Vd4.
add_block('simulink/Signal Routing/Mux',[model '/ResidualMeasurements'],'Inputs','8');
for k = 1:8
    if k<=4, tag=sprintf('w%d',k); else, tag=sprintf('Vd%d',k-4); end
    name = ['ResidualFrom_' tag];
    add_block('simulink/Signal Routing/From',[model '/' name],'GotoTag',tag);
    add_line(model,[name '/1'],sprintf('ResidualMeasurements/%d',k));
end
add_block('simulink/Discrete/Zero-Order Hold',[model '/ResidualSample'], ...
    'SampleTime','residualCfg.Ts');
add_line(model,'ResidualMeasurements/1','ResidualSample/1');
add_block('simulink/Sources/Clock',[model '/ResidualClock']);
add_block('simulink/Discrete/Unit Delay',[model '/ResidualApplied'], ...
    'InitialCondition','zeros(8,1)','SampleTime','residualCfg.Ts');
add_block('simulink/Signal Routing/Demux',[model '/ResidualSplit'],'Outputs','8');
add_line(model,'ResidualApplied/1','ResidualSplit/1');
for i=1:4
    add_line(model,sprintf('ResidualSplit/%d',i),sprintf('DG%d/3',i));
    add_line(model,sprintf('ResidualSplit/%d',i+4),sprintf('DG%d/4',i));
end
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/ResidualGuard']);
rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/ResidualGuard']);
chart.Script = sprintf(['function u = guard(a,previous,x,t)\n' ...
    'u=residual_safety(a,previous,x,t,%s,%s,%.17g,%.17g,true);\nend'], ...
    mat2str(c.limits,17),mat2str(c.slew,17),c.Ts,c.warmup);
add_line(model,'ResidualApplied/1','ResidualGuard/2');
add_line(model,'ResidualSample/1','ResidualGuard/3');
add_line(model,'ResidualClock/1','ResidualGuard/4');
add_line(model,'ResidualGuard/1','ResidualApplied/1');
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/ResidualSignals']);
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/ResidualSignals']);
chart.Script = sprintf(['function [obs,reward,done] = signals(x,u,t)\n' ...
    '[obs,reward,done]=residual_reward(x,u,t,%s);\nend'],mat2str(p,17));
add_line(model,'ResidualSample/1','ResidualSignals/1');
add_line(model,'ResidualApplied/1','ResidualSignals/2');
add_line(model,'ResidualClock/1','ResidualSignals/3');
if strcmp(mode,'agent')
    load_system('rl_lib');
    add_block('rl_lib/RL Agent',[model '/ResidualAgent'],'Agent','residualAgent');
    add_line(model,'ResidualSignals/1','ResidualAgent/1');
    add_line(model,'ResidualSignals/2','ResidualAgent/2');
    add_line(model,'ResidualSignals/3','ResidualAgent/3');
    add_line(model,'ResidualAgent/1','ResidualGuard/1');
else
    value = 'zeros(8,1)';
    if strcmp(mode,'probe'), value = '0.1*ones(8,1)'; end
    add_block('simulink/Sources/Constant',[model '/ResidualAction'], ...
        'Value',value,'SampleTime','residualCfg.Ts');
    add_line(model,'ResidualAction/1','ResidualGuard/1');
end
% Log measurements, physical action, reward and terminal state independently.
sources = {'ResidualSample/1','ResidualApplied/1','ResidualSignals/2','ResidualSignals/3'};
variables = {'residual_x','residual_u','residual_reward_log','residual_done'};
for k=1:4
    name = ['Log_' variables{k}];
    add_block('simulink/Sinks/To Workspace',[model '/' name], ...
        'VariableName',variables{k},'SaveFormat','Timeseries', ...
        'SampleTime','residualCfg.Ts','MaxDataPoints','inf');
    add_line(model,sources{k},[name '/1']);
end
save_system(model,dest);
end
