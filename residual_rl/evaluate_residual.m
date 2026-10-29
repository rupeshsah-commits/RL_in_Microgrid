function report = evaluate_residual(agentFile,c)
if nargin<2, c=residual_config(); end
assert(isfile(agentFile),'Train or resume an agent before evaluation.');
saved=load(agentFile,'residualAgent','c','signature');
assert(isfield(saved,'signature') && strcmp(saved.signature,residual_signature(c)), ...
 'Agent configuration differs; do not evaluate it under silently changed control settings.');
residualAgent=saved.residualAgent; residualAgent.UseExplorationPolicy=false;
assignin('base','residualAgent',residualAgent);
runDir=fullfile(c.results,['evaluation_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
mkdir(runDir); mkdir(fullfile(runDir,'logs')); mkdir(fullfile(runDir,'figures')); mkdir(fullfile(runDir,'tables'));
variants={'original','corrected','corrected','corrected','primary'};
modes={'disabled','disabled','zero','agent','disabled'};
labels={'original_conventional','corrected_conventional','corrected_zero','residual_RL','primary_only'};
models=cell(size(modes)); configs=cell(size(modes));
for k=1:numel(modes)
 cc=c; cc.controllerVariant=variants{k};
 models{k}=build_residual_model(modes{k},cc); configs{k}=cc;
end
scenarios=c.evalScenarios;
rows=struct([]);
for q=1:numel(scenarios)
 for seed=c.testSeeds
  s=residual_scenario(c,scenarios{q},seed);
  for k=1:numel(models)
   model=models{k}; cc=configs{k}; load_system(fullfile(cc.output,[model '.slx']));
   cleanup=onCleanup(@() close_system(model,0));
   rng(seed,'twister'); out=[]; status='failed'; failure='';
   started=tic;
   try
    out=sim(residual_reset(Simulink.SimulationInput(model),cc,s));
    m=residual_metrics(out,cc,s);
    if m.complete && ~m.terminated, status='passed'; else, status='unsafe_or_incomplete'; end
   catch err
    failure=getReport(err,'extended'); m=residual_empty_metrics();
   end
   elapsed=toc(started);
   label=sprintf('%s_%s_seed%d',scenarios{q},labels{k},seed);
   save(fullfile(runDir,'logs',[label '.mat']),'out','s','cc','status','failure','m','elapsed','-v7.3');
   m.scenario=string(scenarios{q}); m.controller=string(labels{k}); m.seed=seed;
   m.status=string(status); m.failure=string(failure);
   m.policySeed=saved.c.seed; m.simulationWallSeconds=elapsed;
   rows=[rows;m]; %#ok<AGROW>
   if ~strcmp(status,'failed')
    plot_residual_results(out,cc,s,label,fullfile(runDir,'figures'));
   end
   clear cleanup
  end
 end
end
report=struct2table(rows);
failed=report(report.status=="failed",{'scenario','controller','seed','failure'});
if ~isempty(report), writetable(report,fullfile(runDir,'tables','comparison.csv')); end
if ~isempty(failed), writetable(failed,fullfile(runDir,'tables','failures.csv')); end
summary=summarize_residual(report);
if ~isempty(summary), writetable(summary,fullfile(runDir,'tables','summary.csv')); end
save(fullfile(runDir,'comparison.mat'),'report','failed','summary','c','agentFile');
plot_baseline_overlay(runDir,c); fprintf('Evaluation results: %s\n',runDir);
end
