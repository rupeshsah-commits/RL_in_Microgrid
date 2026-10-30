function report = check_local_prerequisites(c)
fprintf('MATLAB %s (%s)\n',version,version('-release'));
% Request ver's output struct: bare ver also prints the licence-number header.
products=ver;
for k=1:numel(products)
 fprintf('%s  %s  %s\n',products(k).Name,products(k).Version,products(k).Release);
end
assert(isfile(c.source),'Original load-change SLX missing.');
checksum=residual_hash(c.source);
assert(strcmp(checksum,c.sourceSHA256),'Original source checksum differs.');
report=check_toolbox_access(products,@(name) license('test',name), ...
 @probeReinforcementLearning,@(name) exist(name,'file')~=0);
report.release=version('-release'); report.sourceSHA256=checksum;
warning('ResidualRL:StudyBases','%s. Full training requires ratingsConfirmed=true.',c.ratingEvidence);
end
function result=probeReinforcementLearning()
% Small default TD3 construction exercises real RL access without training.
% Preserve RNG so this diagnostic cannot change later experiment streams.
state=rng; cleanup=onCleanup(@() rng(state)); %#ok<NASGU>
obs=rlNumericSpec([1 1]);
act=rlNumericSpec([1 1],'LowerLimit',-1,'UpperLimit',1);
probe=rlTD3Agent(obs,act); %#ok<NASGU>
result=struct('status','PASS','operation','rlTD3Agent construction', ...
 'trainingRun',false,'simulationRun',false);
end
