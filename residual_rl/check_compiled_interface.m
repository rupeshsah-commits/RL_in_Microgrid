function report = check_compiled_interface(model,c)
% Requires actual MATLAB/Simulink compilation. Never inferred from static syntax.
feval(model,[],[],[],'compile');
cleanup=onCleanup(@() feval(model,[],[],[],'term')); %#ok<NASGU>
iface=[model '/' c.interface];
report.observationWidths=get_param([iface '/Observation'],'CompiledPortWidths');
report.rewardWidths=get_param([iface '/Reward'],'CompiledPortWidths');
report.rewardTypes=get_param([iface '/Reward'],'CompiledPortDataTypes');
report.agentWidths=get_param([iface '/Agent'],'CompiledPortWidths');
report.agentSampleTime=get_param([iface '/Agent'],'CompiledSampleTime');
assert(isequal(report.observationWidths.Outport,c.obsDim));
assert(isequal(report.rewardWidths.Outport,[1 1 9]));
assert(ismember(report.rewardTypes.Outport{2},{'boolean','logical'}),'isDone must be logical.');
assert(strcmp(report.rewardTypes.Outport{1},'double'),'Reward must be double.');
assert(isequal(report.agentWidths.Inport,[c.obsDim 1 1]));
assert(isequal(report.agentWidths.Outport,8));
rates=report.agentSampleTime;
if iscell(rates), rates=vertcat(rates{:}); end
assert(any(abs(rates(:,1)-c.Ts)<1e-12),'Agent sample time mismatch.');
end
