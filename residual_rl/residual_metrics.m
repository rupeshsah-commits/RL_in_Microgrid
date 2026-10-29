function m = residual_metrics(out,c)
x=out.get('residual_x'); u=out.get('residual_u'); d=out.get('residual_done');
t=x.Time(:); y=squeeze(x.Data);
if size(y,1)~=numel(t), y=y.'; end
assert(size(y,2)==8 && all(isfinite(y),'all'),'Invalid measurements.');
assert(t(end)>=c.stopTime-c.Ts,'Incomplete simulation.');
assert(~any(d.Data(:)),'Safety termination encountered; do not report as successful evaluation.');
select=t>=c.warmup; t=t(select); y=y(select,:);
ef=abs(y(:,1:4)/(2*pi)-c.f0); ev=abs(y(:,5:8)/c.v0-1);
m.frequencyIAE=sum(trapz(t,ef));
m.frequencyITAE=sum(trapz(t,t.*ef));
m.frequencyPeakHz=max(ef,[],'all');
m.voltageIAEpu=sum(trapz(t,ev));
m.voltagePeakPU=max(ev,[],'all');
a=squeeze(u.Data);
if size(a,1)~=numel(u.Time), a=a.'; end
assert(size(a,2)==8 && all(isfinite(a),'all'),'Invalid action trace.');
assert(all(abs(a)<=c.limits.'+1e-10,'all'),'Residual amplitude limit exceeded.');
m.residualNormalizedPeak=max(abs(a./c.limits.'),[],'all');
m.residualFrequencyPeakHz=max(abs(a(:,1:4))/(2*pi),[],'all');
m.residualVoltagePeakV=max(abs(a(:,5:8)),[],'all');
end
