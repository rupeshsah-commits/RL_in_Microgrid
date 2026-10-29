function [env,model] = create_residual_environment(agent,c)
assignin('base','residualAgent',agent);
model=build_residual_model('agent',c); load_system(fullfile(c.output,[model '.slx']));
info=get_param(model,'UserData'); assert(~info.agentPlaceholder,'RL Agent placeholder unresolved.');
[obsInfo,actInfo]=residual_specs(c);
env=rlSimulinkEnv(model,[model '/' c.interface '/Agent'],obsInfo,actInfo);
env.ResetFcn=@(in) residual_reset(in,c);
end
