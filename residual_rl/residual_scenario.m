function s = residual_scenario(c,kind,seed)
% A local stream prevents scenario sampling from altering agent RNG state.
g=RandStream('mt19937ar','Seed',seed);
s=struct('name',kind,'seed',seed,'loadP',c.loadP,'loadQ',0, ...
 'switchTimes',c.eventTime,'initialBreaker','open','noiseFraction',0, ...
 'delaySteps',0,'Lscale',1);
if strcmp(kind,'training')
 if c.curriculumStage>=2
  s.loadP=c.loadP*(c.trainLoadRange(1)+diff(c.trainLoadRange)*rand(g));
  s.loadQ=c.trainQRange(1)+diff(c.trainQRange)*rand(g);
  s.switchTimes=c.eventRange(1)+diff(c.eventRange)*rand(g);
 end
 if c.curriculumStage>=3
  s.noiseFraction=c.noiseFractionMax*rand(g);
  s.delaySteps=randi(g,[0 c.delayStepsMax]);
  s.Lscale=1+c.uncertaintyFraction*(2*rand(g)-1);
 end
elseif strcmp(kind,'increase')
 s.loadP=1.4*c.loadP; s.switchTimes=5.5;
elseif strcmp(kind,'decrease')
 s.loadP=1.4*c.loadP; s.initialBreaker='closed'; s.switchTimes=6.5;
elseif strcmp(kind,'reactive')
 s.loadQ=8e3;
elseif strcmp(kind,'noise')
 s.noiseFraction=1.5*c.noiseFractionMax;
elseif strcmp(kind,'delay')
 s.delaySteps=c.delayStepsMax+1;
elseif strcmp(kind,'uncertainty')
 s.Lscale=1+2*c.uncertaintyFraction;
elseif strcmp(kind,'combined')
 s.loadP=1.35*c.loadP; s.loadQ=7e3; s.switchTimes=6.3;
 s.noiseFraction=1.25*c.noiseFractionMax; s.delaySteps=c.delayStepsMax+1;
 s.Lscale=1-1.5*c.uncertaintyFraction;
else
 assert(strcmp(kind,'nominal'),'Unknown scenario.');
end
s.switchTimes=round(s.switchTimes/c.plantTs)*c.plantTs;
end
