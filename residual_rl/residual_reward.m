function [reward,done,parts] = residual_reward(x,u,previous,t,p,oldCommand)
%#codegen
% parts: 7 unweighted costs then two bounded priority multipliers.
if nargin<6, oldCommand=zeros(8,1); end
f=x(1:4)/(2*pi); v=hypot(x(5:8),x(17:20));
P=x(9:12)./p.Prated; Q=x(13:16)./p.Qrated;
invalid=any(~isfinite(x)) || any(~isfinite(u)) || any(~isfinite(previous)) || any(~isfinite(oldCommand));
done=invalid || (t>=p.warmup && (any(abs(f-p.f0)>p.tripHz) || ...
 any(abs(v/p.v0-1)>p.tripVoltagePU)));
a=u./p.limits; old=previous./p.limits;
soft=[max(abs(f-p.f0)/p.softHz-1,0); ...
 max(abs(v/p.v0-1)/p.softVoltagePU-1,0); ...
 max(abs(P)/p.softPowerPU-1,0);max(abs(Q)/p.softPowerPU-1,0)];
priority=residual_priorities(x,p);
components=[mean(((f-p.f0)/p.fScale).^2);mean(((v-p.v0)/p.vScale).^2); ...
 mean((P-mean(P)).^2);mean((Q-mean(Q)).^2);mean(a.^2); ...
 mean((a-old).^2);mean(soft.^2)];
parts=[components;priority];
w=p.rewardWeights; w(1:2)=w(1:2).*priority;
cost=sum(w.*components);
if invalid || ~isfinite(cost)
 cost=0; done=true; parts=zeros(9,1);
end
reward=-p.Ts*cost;
if t<p.warmup, reward=0; end
if done, reward=reward-p.terminalPenalty; end
end
