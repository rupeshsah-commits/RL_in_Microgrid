function report = evaluate_residual(agentFile)
% Paired comparisons: same switched load and RNG seed, exploration disabled.
c = residual_config();
saved = load(agentFile,'residualAgent','c');
fields = {'root','source','output','results'};
assert(isequaln(rmfield(saved.c,fields),rmfield(c,fields)), ...
    'Agent control configuration differs from current configuration.');
residualAgent = saved.residualAgent;
residualAgent.UseExplorationPolicy = false;
assignin('base','residualAgent',residualAgent);
models = {build_residual_model('zero',c),build_residual_model('agent',c)};
runDir=fullfile(c.results,['evaluation_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
if ~isfolder(runDir), mkdir(runDir); end
rows = struct([]);
for s = 1:numel(c.evalScales)
    for k = 1:2
        model=models{k}; load_system(fullfile(c.output,[model '.slx']));
        cleanup=onCleanup(@() close_system(model,0));
        rng(c.evalSeeds(s),'twister');
        in=residual_reset(Simulink.SimulationInput(model),c,c.evalScales(s));
        out=[];
        try
            out=sim(in); metrics=residual_metrics(out,c);
            metrics.status="passed"; metrics.failure="";
        catch err
            names={'frequencyIAE','frequencyITAE','frequencyPeakHz','voltageIAEpu', ...
                'voltagePeakPU','residualNormalizedPeak','residualFrequencyPeakHz', ...
                'residualVoltagePeakV'};
            metrics=cell2struct(num2cell(nan(size(names))),names,2);
            metrics.status="failed"; metrics.failure=string(err.message);
        end
        metrics.loadScale=c.evalScales(s); metrics.seed=c.evalSeeds(s);
        metrics.controller=string({'conventional','residual'}); metrics.controller=metrics.controller(k);
        save(fullfile(runDir,sprintf('scenario_%d_mode_%d.mat',s,k)), ...
            'out','metrics','c');
        rows(end+1)=metrics; %#ok<AGROW>
        clear cleanup
    end
end
report=struct2table(rows);
writetable(report,fullfile(runDir,'comparison.csv'));
save(fullfile(runDir,'comparison.mat'),'report','c','agentFile');
disp(report);
end
