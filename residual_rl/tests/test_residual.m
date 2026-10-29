function tests=test_residual
tests=functiontests(localfunctions);
end
function [c,p,x]=nominal()
c=residual_config(); p=residual_parameters(c);
x=[repmat(c.omega0,4,1);repmat(c.v0,4,1);zeros(12,1)];
end
function testConfig(t)
c=residual_config(); validate_config(c);
verifyFalse(t,c.allowFullTraining); verifyFalse(t,c.ratingsConfirmed);
verifyEqual(t,residual_hash(c.source),c.sourceSHA256);
end
function testSignalMap(t)
c=residual_config(); m=model_signal_map(c.sourceName);
verifyEqual(t,m.rawDimension,20); verifyEqual(t,m.observationDimension,42);
verifyEqual(t,m.measurementPorts{1},[1 1 1 1 2]);
verifyEqual(t,m.voltageInjection{4},[c.sourceName '/DG4/Sum6']);
end
function testObservation(t)
[c,p,x]=nominal(); o=residual_observation(x,zeros(8,1),zeros(8,1),p);
verifySize(t,o,[42 1]); verifyEqual(t,o(1:40),zeros(40,1));
verifyEqual(t,o(41:42),ones(2,1));
x(1)=Inf; o=residual_observation(x,zeros(8,1),zeros(8,1),p);
verifyTrue(t,all(isfinite(o))); verifyLessThanOrEqual(t,abs(o),c.obsClip*ones(42,1));
end
function testBoundsAndRate(t)
[c,p,x]=nominal(); old=zeros(8,1);
for k=1:100
 a=2*(-1)^k*ones(8,1); [u,~]=residual_safety(a,old,x,1,true,p);
 verifyLessThanOrEqual(t,abs(u),c.limits+1e-12);
 verifyLessThanOrEqual(t,abs(u-old),c.slew*c.Ts+1e-12); old=u;
end
end
function testFallback(t)
[c,p,x]=nominal();
for bad=[NaN Inf -Inf]
 a=zeros(8,1); a(4)=bad;
 [u,hit]=residual_safety(a,c.limits,x,1,true,p);
 verifyEqual(t,u,zeros(8,1)); verifyTrue(t,hit);
end
[u,~]=residual_safety(ones(8,1),c.limits,x,1,false,p); verifyEqual(t,u,zeros(8,1));
[u,~]=residual_safety(ones(8,1),c.limits,x,0,true,p); verifyEqual(t,u,zeros(8,1));
x(1)=2*pi*(c.f0+c.tripHz+1);
[u,hit]=residual_safety(ones(8,1),c.limits,x,1,true,p);
verifyEqual(t,u,zeros(8,1)); verifyTrue(t,hit);
end
function testPerfectReward(t)
[~,p,x]=nominal(); [r,d,parts]=residual_reward(x,zeros(8,1),zeros(8,1),1,p);
verifyEqual(t,r,0); verifyFalse(t,d); verifyEqual(t,parts(1:7),zeros(7,1));
end
function testIsolatedObjectives(t)
[c,p,base]=nominal();
for target=1:4
 x=base;
 if target==1, x(1)=x(1)+2*pi*0.1;
 elseif target==2, x(5)=x(5)+0.01*c.v0;
 elseif target==3, x(9)=0.1*c.Prated(1);
 else, x(13)=0.1*c.Qrated(1); end
 [r,d,parts]=residual_reward(x,zeros(8,1),zeros(8,1),1,p);
 verifyLessThan(t,r,0); verifyFalse(t,d); verifyGreaterThan(t,parts(target),0);
 others=setdiff(1:4,target); verifyEqual(t,parts(others),zeros(3,1));
end
end
function testEffortAndActionRate(t)
[c,p,x]=nominal();
[~,~,parts]=residual_reward(x,c.limits,zeros(8,1),1,p);
verifyEqual(t,parts(5:6),ones(2,1));
end
function testUnsafeAndInvalidReward(t)
[c,p,x]=nominal(); x(5)=c.v0*(1+c.tripVoltagePU+0.01);
[r,d,~]=residual_reward(x,zeros(8,1),zeros(8,1),1,p);
verifyTrue(t,d); verifyLessThanOrEqual(t,r,-c.terminalPenalty);
for bad=[NaN Inf -Inf]
 x(5)=bad; [r,d,parts]=residual_reward(x,zeros(8,1),zeros(8,1),1,p);
 verifyTrue(t,d); verifyTrue(t,isfinite(r)); verifyTrue(t,all(isfinite(parts)));
end
end
function testVoltageAntiwindup(t)
[c,p,x]=nominal(); x(5:8)=0.9*c.v0;
rate=conventional_voltage_rate(x,zeros(4,1),p); verifyGreaterThan(t,rate,zeros(4,1));
rate=conventional_voltage_rate(x,repmat(c.secondaryVLimit/c.secondaryGain,4,1),p);
verifyEqual(t,rate,zeros(4,1));
end
function testNormalizationUnequal(t)
[c,p,x]=nominal(); p.Prated=c.Prated.*[1;2;3;4];
x(9:12)=0.3*p.Prated; [~,~,parts]=residual_reward(x,zeros(8,1),zeros(8,1),1,p);
verifyEqual(t,parts(3),0,'AbsTol',1e-14);
end
function testAdaptiveBounds(t)
[c,p,x]=nominal(); x(1)=x(1)+2*pi*c.tripHz;
priorities=residual_priorities(x,p);
verifyLessThanOrEqual(t,priorities,c.priorityMax*ones(2,1));
p.adaptiveWeights=0; verifyEqual(t,residual_priorities(x,p),ones(2,1));
end
function testScenarioReproducibility(t)
c=residual_config(); c.curriculumStage=3;
a=residual_scenario(c,'training',42); b=residual_scenario(c,'training',42);
verifyEqual(t,a,b); verifyLessThanOrEqual(t,a.delaySteps,c.delayStepsMax);
verifyEqual(t,make_residual_noise(c,a).Data,make_residual_noise(c,b).Data);
end

function testDelayedInvalidActionTerminates(t)
[~,p,x]=nominal(); a=zeros(8,1); a(1)=NaN;
[r,d,~]=residual_reward(x,zeros(8,1),zeros(8,1),1,p,a);
verifyTrue(t,d); verifyTrue(t,isfinite(r));
end
