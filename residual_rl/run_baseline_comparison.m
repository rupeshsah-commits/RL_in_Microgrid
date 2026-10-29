function report = run_baseline_comparison(agentFile,c)
if nargin<2, c=residual_config(); end
report=evaluate_residual(agentFile,c);
end
