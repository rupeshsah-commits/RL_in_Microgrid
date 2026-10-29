function require_validation(c)
path=fullfile(c.results,'logs','validation.mat');
assert(isfile(path),'Run RUN_ME_FIRST successfully before training.');
saved=load(path,'report');
assert(isfield(saved.report,'signature') && ...
 strcmp(saved.report.signature,residual_signature(c)), ...
 'Validation is missing or belongs to a different configuration/source revision. Run RUN_ME_FIRST.');
assert(strcmp(saved.report.environment,'PASS'),'Environment validation did not pass.');
end
