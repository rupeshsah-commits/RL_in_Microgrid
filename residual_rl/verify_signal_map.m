function map = verify_signal_map(model,c)
% Fail closed and retain diagnostics if model hierarchy differs from the audit.
map=model_signal_map(model); report=struct('model',model,'status','PENDING','errors',{{}});
try
 for i=1:4
  get_param(map.dg{i},'Handle');
  for j=1:5
   src=map.measurementSources{i}{j}; ph=get_param(src,'PortHandles');
   assert(numel(ph.Outport)>=map.measurementPorts{i}(j),'Missing measurement port.');
  end
  assert(strcmp(get_param([map.dg{i} '/abc2dq0'],'Power'),'Power Variant'), ...
      'Voltage transform normalization changed.');
  assert(strcmp(get_param([map.dg{i} '/From32'],'GotoTag'),'P'));
  assert(strcmp(get_param([map.dg{i} '/From33'],'GotoTag'),'Q'));
  for j=1:2
   gains={map.omegaGain{i},map.voltageGain{i}};
   sums={map.omegaInjection{i},map.voltageInjection{i}};
   assert(str2double(get_param(gains{j},'Gain'))==c.secondaryGain);
   assert(strcmp(get_param(sums{j},'Inputs'),'|-++'));
   ph=get_param(gains{j},'PortHandles'); line=get_param(ph.Outport(1),'Line');
   dst=get_param(line,'DstPortHandle');
   assert(numel(dst)==1 && strcmp(get_param(dst,'Parent'),sums{j}) && ...
       get_param(dst,'PortNumber')==2,'Unverified injection connection.');
  end
 end
 assert(strcmp(get_param(map.powergui,'SimulationMode'),'Discrete'));
 assert(abs(str2double(get_param(map.powergui,'SampleTime'))-c.plantTs)<eps);
 report.status='PASS';
catch err
 report.status='FAIL'; report.errors={err.message};
 if ~isfolder(c.output), mkdir(c.output); end
 save(fullfile(c.output,'signal_mapping_report.mat'),'map','report');
 error('ResidualRL:SignalMap','Signal mapping failed: %s. See generated/signal_mapping_report.mat',err.message);
end
if ~isfolder(c.output), mkdir(c.output); end
save(fullfile(c.output,'signal_mapping_report.mat'),'map','report');
end
