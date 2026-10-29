function [xPath,xiPath] = tap_model_measurements(model,c)
% Expose only a branch of existing measurement ports, never alter the plant.
m=model_signal_map(model);
xPath=[model '/ResidualMeasurements']; xiPath=[model '/ResidualSecondaryStates'];
add_block('simulink/Signal Routing/Mux',xPath,'Inputs','20','Position',[2450 30 2455 530]);
add_block('simulink/Signal Routing/Mux',xiPath,'Inputs','8','Position',[2450 600 2455 850]);
for i=1:4
 d=m.dg{i};
 add_block('built-in/Outport',[d '/ResidualVq'],'Port','5');
 wire(d,[d '/Demux'],2,[d '/ResidualVq'],1);
 ports=[1 3 2 4 5];
 for group=1:5, wire(model,d,ports(group),xPath,(group-1)*4+i); end
 names={m.frequencyIntegrators{i},m.voltageIntegrators{i}};
 for group=1:2
  g=sprintf('%s/ResidualStateScale%d_%d',model,group,i);
  add_block('simulink/Math Operations/Gain',g,'Gain',num2str(c.secondaryGain*~strcmp(c.controllerVariant,'primary')));
  wire(model,[model '/' names{group}],1,g,1);
  wire(model,g,1,xiPath,(group-1)*4+i);
 end
end
end
function wire(sys,src,sp,dst,dp)
a=get_param(src,'PortHandles'); b=get_param(dst,'PortHandles');
add_line(sys,a.Outport(sp),b.Inport(dp),'autorouting','on');
end
