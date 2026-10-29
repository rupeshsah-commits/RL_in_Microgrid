function [agent,obsInfo,actInfo] = residual_agent(c)
obsInfo = rlNumericSpec([16 1],'LowerLimit',-20,'UpperLimit',20);
obsInfo.Name = 'frequency_voltage_previous_residual';
actInfo = rlNumericSpec([8 1],'LowerLimit',-1,'UpperLimit',1);
actInfo.Name = 'normalized_residual';
% Zero output initialization starts the actor at conventional control.
actorNet = [featureInputLayer(16,'Normalization','none','Name','obs')
    fullyConnectedLayer(128,'Name','a1'); reluLayer('Name','ar1')
    fullyConnectedLayer(128,'Name','a2'); reluLayer('Name','ar2')
    fullyConnectedLayer(8,'Name','action','WeightsInitializer','zeros', ...
        'BiasInitializer','zeros'); tanhLayer('Name','bounded')];
actor = rlContinuousDeterministicActor(dlnetwork(actorNet),obsInfo,actInfo);
obsPath = featureInputLayer(16,'Normalization','none','Name','obs');
actPath = featureInputLayer(8,'Normalization','none','Name','act');
common = [concatenationLayer(1,2,'Name','concat')
    fullyConnectedLayer(128); reluLayer
    fullyConnectedLayer(128); reluLayer; fullyConnectedLayer(1)];
g = layerGraph(obsPath); g = addLayers(g,actPath); g = addLayers(g,common);
g = connectLayers(g,'obs','concat/in1');
g = connectLayers(g,'act','concat/in2');
critic = rlQValueFunction(dlnetwork(g),obsInfo,actInfo, ...
    'ObservationInputNames','obs','ActionInputNames','act');
o = rlDDPGAgentOptions('SampleTime',c.Ts,'MiniBatchSize',128, ...
    'ExperienceBufferLength',1e6);
o.NoiseOptions.StandardDeviation = 0.1;
o.NoiseOptions.StandardDeviationDecayRate = 1e-5;
o.ActorOptimizerOptions.LearnRate = 1e-4;
o.CriticOptimizerOptions.LearnRate = 1e-3;
agent = rlDDPGAgent(actor,critic,o);
end
