function obs = residual_observation(x,u,xi,p)
%#codegen
% 42 elements; xi contains physical secondary omega/V corrections.
f=x(1:4)/(2*pi); v=hypot(x(5:8),x(17:20));
P=x(9:12)./p.Prated; Q=x(13:16)./p.Qrated;
obs=[(f-p.f0)/p.fScale;(v-p.v0)/p.vScale;P;Q; ...
 P-mean(P);Q-mean(Q);u./p.limits; ...
 xi(1:4)/p.secondaryWLimit;xi(5:8)/p.secondaryVLimit;residual_priorities(x,p)];
obs(~isfinite(obs))=0; obs=min(max(obs,-p.obsClip),p.obsClip);
end
