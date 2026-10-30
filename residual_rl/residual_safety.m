function [u,intervention] = residual_safety(a,previous,x,t,enabled,p)
%#codegen
% u is physical [rad/s(4); V(4)]. Emergency bypass overrides nominal slew.
u=zeros(8,1); intervention=false;
invalid=any(~isfinite(a)) || any(~isfinite(previous)) || any(~isfinite(x));
v=hypot(x(5:8),x(17:20));
unsafe=t>=p.warmup && (any(abs(x(1:4)/(2*pi)-p.f0)>p.tripHz) || ...
 any(abs(v/p.v0-1)>p.tripVoltagePU));
if ~enabled || t<p.warmup || invalid || unsafe
 intervention=invalid || unsafe; return
end
% Ablation disables only slew/smoothing, retaining mandatory hard bounds/fallback.
target=min(max(a(:),-1),1).*p.limits;
if p.safetyEnabled~=0
 alpha=p.Ts/(p.smoothingTau+p.Ts);
 smooth=previous+alpha*(target-previous);
 u=previous+min(max(smooth-previous,-p.slew*p.Ts),p.slew*p.Ts);
else
 u=target;
end
u=min(max(u,-p.limits),p.limits);
intervention=any(abs(a)>1) || any(abs(u-target)>1e-10);
end
