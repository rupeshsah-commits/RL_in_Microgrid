function report = check_toolbox_access(products,featureTester,rlProbe,apiChecker)
% Installed products, advisory feature hints, and real API access are distinct.
% Function handles allow regression tests without checking out any licence.
required={'MATLAB','Simulink','Simscape','Simscape Electrical', ...
 'Reinforcement Learning Toolbox','Deep Learning Toolbox'};
features={{'MATLAB'},{'Simulink'},{'Simscape'}, ...
 {'Power_System_Blocks','Simscape_Electrical'}, ...
 {'Reinforcement_Learning_Toolbox'},{'Neural_Network_Toolbox'}};
report.products=products; report.requiredProducts=required;
report.installed=ismember(required,{products.Name});
report.licenseHints=false(size(required));
report.licenseHintErrors=cell(size(required));
for k=1:numel(required)
 for j=1:numel(features{k})
  try
   report.licenseHints(k)=report.licenseHints(k)||logical(featureTester(features{k}{j}));
  catch err
   report.licenseHintErrors{k}=err.identifier;
  end
 end
 fprintf('%s: installed=%d; advisory licence hint=%d\n', ...
  required{k},report.installed(k),report.licenseHints(k));
end
if ~all(report.installed)
 error('ResidualRL:MissingProducts','Required products not installed: %s', ...
  strjoin(required(~report.installed),', '));
end
apis={'rlNumericSpec','rlTD3Agent'};
for k=1:numel(apis)
 if ~apiChecker(apis{k})
  error('ResidualRL:MissingRLAPI', ...
   'Installed RL product has no accessible %s entry point. Check the local MATLAB path.',apis{k});
 end
end
% A zero/unknown feature query is not promoted to a missing-product diagnosis.
% Real licensing or API-use failures remain fatal and retain their original cause.
try
 report.rlConstructorProbe=rlProbe();
catch err
 failure=MException('ResidualRL:RLAccessProbeFailed', ...
  'RL constructor access probe failed before model validation: %s',err.message);
 failure=addCause(failure,err); throw(failure);
end
fprintf('RL TD3 constructor probe succeeded (no training or simulation).\n');
report.runtimeScope='RL constructor only; model compilation and simulation not checked here';
end
