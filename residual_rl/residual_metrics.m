function m = residual_metrics(out,c,s)
if nargin<3, s=residual_scenario(c,'nominal',c.validationSeeds(1)); end
[t,x]=residual_series(out,'residual_x',20);
[tu,u]=residual_series(out,'residual_u',8);
[~,done]=residual_series(out,'residual_done',1);
[~,interventions]=residual_series(out,'residual_intervention',1);
[~,reward]=residual_series(out,'residual_reward_log',1); %#ok<ASGLU>
assert(all(abs(u)<=c.limits.'+1e-10,'all'),'Physical residual bound violated.');
select=t>=c.warmup; time=t(select); x=x(select,:);
f=x(:,1:4)/(2*pi); v=hypot(x(:,5:8),x(:,17:20))/c.v0;
ef=f-c.f0; ev=v-1; P=x(:,9:12)./c.Prated.'; Q=x(:,13:16)./c.Qrated.';
m.frequencyPeakHz=max(abs(ef),[],'all'); m.frequencyNadirHz=min(f,[],'all');
m.frequencyZenithHz=max(f,[],'all');
m.frequencyIAE=sum(trapz(time,abs(ef))); m.frequencyISE=sum(trapz(time,ef.^2));
m.frequencyITAE=sum(trapz(time,time.*abs(ef)));
m.voltagePeakPU=max(abs(ev),[],'all'); m.voltageIAE=sum(trapz(time,abs(ev)));
m.voltageISE=sum(trapz(time,ev.^2)); m.voltageITAE=sum(trapz(time,time.*abs(ev)));
m.frequencySettlingSeconds=settling(time,max(abs(ef),[],2),c.settleHz,max(s.switchTimes));
m.voltageSettlingSeconds=settling(time,max(abs(ev),[],2),c.settleVoltagePU,max(s.switchTimes));
m.activeSharingRMSE=sqrt(mean((P-mean(P,2)).^2,'all'));
m.reactiveSharingRMSE=sqrt(mean((Q-mean(Q,2)).^2,'all'));
a=u./c.limits.'; m.residualNormalizedPeak=max(abs(a),[],'all');
m.residualNormalizedRMS=sqrt(mean(a.^2,'all'));
m.residualFrequencyPeakHz=max(abs(u(:,1:4))/(2*pi),[],'all');
m.residualVoltagePeakV=max(abs(u(:,5:8)),[],'all');
m.actionSlewRMS=sqrt(mean((diff(a)./diff(tu)).^2,'all'));
m.limitedSamples=sum(interventions~=0); m.hardUnsafeSamples=sum(done~=0);
m.terminated=any(done~=0); m.complete=t(end)>=c.stopTime-c.Ts;
m.decisionTimeSeconds=NaN; % Not measured: simulator elapsed time is not policy inference time.
end
function value=settling(t,error,tol,event)
idx=find(t>=event); value=NaN;
if isempty(idx), return; end
last=find(error(idx)>tol,1,'last');
if isempty(last), value=t(idx(1))-event;
elseif last<numel(idx), value=t(idx(last+1))-event; end
end
