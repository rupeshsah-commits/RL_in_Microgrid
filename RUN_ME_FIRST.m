% Build, inspect and validate only. No training is started.
projectRoot=fileparts(mfilename('fullpath')); addpath(fullfile(projectRoot,'residual_rl'));
c=residual_config(); setupReport=struct('status','NOT RUN','runtime','PENDING');
logFolder=fullfile(c.results,'logs'); if ~isfolder(logFolder), mkdir(logFolder); end
logPath=fullfile(logFolder,['setup_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')) '.txt']);
diary(logPath); diaryCleanup=onCleanup(@() diary('off'));
try
 setupReport.prerequisites=check_local_prerequisites(c);
 setupReport.validation=validate_residual(c);
 setupReport.status='PASS'; setupReport.runtime='Executed locally; see per-check report';
 save(fullfile(logFolder,'setup_report.mat'),'setupReport');
 fprintf('Setup validation completed. Next command: RUN_SMOKE_TEST\n');
catch err
 setupReport.status='FAIL'; setupReport.failure=getReport(err,'extended');
 save(fullfile(logFolder,'setup_report.mat'),'setupReport');
 rethrow(err)
end
clear diaryCleanup
