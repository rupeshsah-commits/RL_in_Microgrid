function rate = conventional_voltage_rate(x,rawState,p)
%#codegen
% Reuse existing voltage integrators and Gain9 (5); no duplicate integrator.
v=hypot(x(5:8),x(17:20)); Q=x(13:16)./p.Qrated;
physical=p.secondaryGain*rawState;
drive=p.kV*(1-v/p.v0)+p.kQshare*(p.adjacency*Q-sum(p.adjacency,2).*Q);
for i=1:4
 if ~isfinite(drive(i)) || ~isfinite(physical(i)) || ...
   (physical(i)>=p.secondaryVLimit-1e-10 && drive(i)>0) || ...
   (physical(i)<=-p.secondaryVLimit+1e-10 && drive(i)<0)
  drive(i)=0;
 end
end
rate=drive/p.secondaryGain;
end
