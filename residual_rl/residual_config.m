function c = residual_config()
% Study bases are NOT manufacturer ratings. Confirm before full training.
c.root=fileparts(fileparts(mfilename('fullpath')));
c.sourceName='Load_Changes_AC_Droop_four_inverter';
c.source=fullfile(c.root,[c.sourceName '.slx']);
c.sourceSHA256='3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123';
c.model='Residual_RL_Load_Changes_AC_Droop_four_inverter';
c.interface='Residual_RL_Interface'; c.agentBlock=[c.model '/' c.interface '/Agent'];
c.output=fullfile(c.root,'generated'); c.results=fullfile(c.root,'results');
c.controllerVariant='corrected'; % 'original' reproduces unmodified equations
c.enableResidual=true; c.safetyEnabled=true; c.adaptiveWeights=true;
c.allowFullTraining=false; c.ratingsConfirmed=false;
c.f0=60; c.omega0=2*pi*c.f0; c.v0=338.8460811;
c.voltageDefinition='amplitude-invariant dq magnitude, phase-peak equivalent when balanced';
c.Pbase=50e3; c.Qbase=50e3; % 200 kW total nominal loaded case / four DGs
c.Prated=repmat(c.Pbase,4,1); c.Qrated=repmat(c.Qbase,4,1);
c.ratingEvidence='Equal study normalization bases; hardware ratings absent from archive';
c.mp=repmat(1e-4,4,1); c.nq=repmat(1e-4,4,1);
c.secondaryGain=5; c.kV=5; c.kQshare=c.secondaryGain*1e-4*c.Qbase;
c.kPshare=1e-4*c.Pbase;
c.secondaryVLimit=0.10*c.v0; c.secondaryWLimit=2*pi*3;
c.adjacency=[0 1 0 1;1 0 1 0;0 1 0 1;1 0 1 0];
c.pin=[1;0;0;0]; c.powerFilterRadSec=60;
c.Ts=0.02; c.plantTs=2e-6; c.solver='ode4'; c.solverStep=2e-6;
c.stopTime=15; c.warmup=0.5; c.eventTime=6;
c.loadP=20e3; c.loadQ=0; c.eventRange=[5 7];
c.fScale=0.2; c.vScale=0.02*c.v0; c.obsClip=20; c.obsDim=42;
c.limits=[repmat(2*pi*0.2,4,1);repmat(0.02*c.v0,4,1)];
c.slew=[repmat(2*pi*0.5,4,1);repmat(0.05*c.v0,4,1)]; c.smoothingTau=0.04;
c.tripHz=3; c.tripVoltagePU=0.20; c.softHz=0.5; c.softVoltagePU=0.05;
c.softPowerPU=1.2; c.terminalPenalty=100;
c.rewardWeights=[1;1;0.2;0.2;0.02;0.01;1];
c.priorityMax=4; c.settleHz=0.1; c.settleVoltagePU=0.02;
c.equivalenceAbsTol=1e-5; c.equivalenceRelTol=1e-7;
c.curriculumStage=1; c.trainLoadRange=[0.8 1.2]; c.trainQRange=[0 5e3];
c.noiseFractionMax=0.002; c.delayStepsMax=2; c.uncertaintyFraction=0.03;
c.evalScenarios={'nominal','increase','decrease','reactive','noise','delay','uncertainty','combined'};
c.trainSeeds=[42 43 44]; c.validationSeeds=[101 102 103]; c.testSeeds=[901 902 903];
c.seed=c.trainSeeds(1); c.episodes=100; c.smokeEpisodes=2;
c.batchSize=128; c.bufferLength=1e6; c.warmStartSteps=256;
c.actorRate=1e-4; c.criticRate=1e-3; c.gradientThreshold=1;
c.checkpointEvery=5; c.algorithm='TD3';
end
