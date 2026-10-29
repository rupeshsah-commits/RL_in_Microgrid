function report = check_local_prerequisites(c)
fprintf('MATLAB %s (%s)\n',version,version('-release')); ver;
features={{'MATLAB'},{'Simulink'},{'Simscape'}, ...
 {'Power_System_Blocks','Simscape_Electrical'}, ...
 {'Reinforcement_Learning_Toolbox'},{'Neural_Network_Toolbox'}};
report.release=version('-release'); report.licenseTests=false(size(features));
for k=1:numel(features)
 for j=1:numel(features{k})
  try
   report.licenseTests(k)=report.licenseTests(k)||logical(license('test',features{k}{j}));
  catch
   % Unknown feature names are not successful licence checks.
  end
 end
 fprintf('Product group %d licence availability: %d\n',k,report.licenseTests(k));
end
assert(all(report.licenseTests),'A required product is unavailable; see ver and local product setup.');
assert(isfile(c.source),'Original load-change SLX missing.');
report.sourceSHA256=residual_hash(c.source);
assert(strcmp(report.sourceSHA256,c.sourceSHA256),'Original source checksum differs.');
warning('ResidualRL:StudyBases','%s. Full training requires ratingsConfirmed=true.',c.ratingEvidence);
end
