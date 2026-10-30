function [agent,obsInfo,actInfo] = residual_agent(c)
[obsInfo,actInfo]=residual_specs(c);
a=[featureInputLayer(c.obsDim,'Normalization','none','Name','obs')
 fullyConnectedLayer(128,'Name','a1');reluLayer('Name','ar1')
 fullyConnectedLayer(128,'Name','a2');reluLayer('Name','ar2')
 fullyConnectedLayer(8,'Name','action','WeightsInitializer','zeros','BiasInitializer','zeros')
 tanhLayer('Name','bounded')];
actor=rlContinuousDeterministicActor(dlnetwork(a),obsInfo,actInfo);
critics(1)=makeCritic(obsInfo,actInfo,c); critics(2)=makeCritic(obsInfo,actInfo,c);
o=rlTD3AgentOptions('SampleTime',c.Ts,'MiniBatchSize',c.batchSize, ...
 'ExperienceBufferLength',c.bufferLength);
o.NumWarmStartSteps=c.warmStartSteps;
o.ResetExperienceBufferBeforeTraining=false;
o.ActorOptimizerOptions.LearnRate=c.actorRate;
o.ActorOptimizerOptions.GradientThreshold=c.gradientThreshold;
for k=1:numel(o.CriticOptimizerOptions)
 o.CriticOptimizerOptions(k).LearnRate=c.criticRate;
 o.CriticOptimizerOptions(k).GradientThreshold=c.gradientThreshold;
end
o.ExplorationModel.StandardDeviation=0.1;
o.TargetPolicySmoothModel.StandardDeviation=0.1;
agent=rlTD3Agent(actor,critics,o);
end
function critic=makeCritic(obsInfo,actInfo,c)
o=featureInputLayer(c.obsDim,'Normalization','none','Name','obs');
a=featureInputLayer(8,'Normalization','none','Name','act');
common=[concatenationLayer(1,2,'Name','concat');fullyConnectedLayer(128)
 reluLayer;fullyConnectedLayer(128);reluLayer;fullyConnectedLayer(1)];
g=layerGraph(o); g=addLayers(g,a); g=addLayers(g,common);
g=connectLayers(g,'obs','concat/in1'); g=connectLayers(g,'act','concat/in2');
critic=rlQValueFunction(dlnetwork(g),obsInfo,actInfo, ...
 'ObservationInputNames','obs','ActionInputNames','act');
end
