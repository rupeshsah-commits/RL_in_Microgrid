function weights = residual_priorities(x,p)
%#codegen
f=x(1:4)/(2*pi); v=hypot(x(5:8),x(17:20));
weights=ones(2,1);
if p.adaptiveWeights~=0 && all(isfinite(x))
 proximity=[max(abs(f-p.f0))/p.softHz; max(abs(v/p.v0-1))/p.softVoltagePU];
 weights=1+(p.priorityMax-1)*min(max(proximity,0),1).^2;
end
end
