function tests=test_residual
tests=functiontests(localfunctions);
end
function testBoundsAndSlew(t)
c=residual_config(); x=[repmat(2*pi*c.f0,4,1);repmat(c.v0,4,1)];
u=zeros(8,1);
for k=1:100
    a=2*(-1)^k*ones(8,1);
    next=residual_safety(a,u,x,1,c.limits,c.slew,c.Ts,c.warmup,true);
    verifyLessThanOrEqual(t,abs(next),c.limits+1e-12);
    verifyLessThanOrEqual(t,abs(next-u),c.slew*c.Ts+1e-12); u=next;
end
end
function testDisableAndInvalid(t)
c=residual_config(); x=ones(8,1);
for mode=1:4
    a=ones(8,1); time=1; enabled=true;
    if mode==1
        a(1)=NaN;
    elseif mode==2
        time=0;
    elseif mode==3
        enabled=false;
    else
        x(1)=Inf;
    end
    u=residual_safety(a,c.limits,x,time,c.limits,c.slew,c.Ts,c.warmup,enabled);
    verifyEqual(t,u,zeros(8,1));
end
end
function testReward(t)
c=residual_config(); p=[c.f0;c.v0;c.fScale;c.vScale;c.tripHz; ...
 c.tripVoltagePU;c.warmup;c.Ts;c.rewardWeights(:);c.terminalPenalty;c.limits];
x=[repmat(2*pi*c.f0,4,1);repmat(c.v0,4,1)];
[o,r,d]=residual_reward(x,zeros(8,1),1,p);
verifyEqual(t,o,zeros(16,1)); verifyEqual(t,r,0); verifyFalse(t,d);
x(1)=NaN; [o,r,d]=residual_reward(x,zeros(8,1),1,p);
verifyTrue(t,d); verifyTrue(t,all(isfinite(o))); verifyEqual(t,r,-c.terminalPenalty);
x(1)=2*pi*(c.f0+c.tripHz+1); [~,~,d]=residual_reward(x,zeros(8,1),1,p);
verifyTrue(t,d);
end

function testVoltageTripAndEffort(t)
c=residual_config(); p=[c.f0;c.v0;c.fScale;c.vScale;c.tripHz; ...
 c.tripVoltagePU;c.warmup;c.Ts;c.rewardWeights(:);c.terminalPenalty;c.limits];
x=[repmat(2*pi*c.f0,4,1);repmat(c.v0,4,1)];
[~,r,~]=residual_reward(x,c.limits,1,p); verifyLessThan(t,r,0);
x(5)=c.v0*(1+c.tripVoltagePU+0.01);
[~,r,d]=residual_reward(x,zeros(8,1),1,p);
verifyTrue(t,d); verifyLessThanOrEqual(t,r,-c.terminalPenalty);
end
