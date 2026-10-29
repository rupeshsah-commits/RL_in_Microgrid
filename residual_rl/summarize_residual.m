function result = summarize_residual(T)
% No pooling across distinct scenarios. Unsafe rows excluded; failure rates retained.
rows=struct([]); if isempty(T), result=table(); return; end
metrics={'frequencyIAE','frequencyPeakHz','voltageIAE','voltagePeakPU', ...
 'activeSharingRMSE','reactiveSharingRMSE','residualNormalizedRMS'};
groups=unique(T(:,{'scenario','controller'}),'rows');
for g=1:height(groups)
 mask=T.scenario==groups.scenario(g)&T.controller==groups.controller(g);
 allRows=T(mask,:); good=allRows(allRows.status=="passed",:);
 for j=1:numel(metrics)
  y=good.(metrics{j}); y=y(isfinite(y)); n=numel(y);
  a=struct('scenario',groups.scenario(g),'controller',groups.controller(g), ...
   'metric',string(metrics{j}),'n',n,'mean',NaN,'std',NaN,'median',NaN, ...
   'ci95Low',NaN,'ci95High',NaN,'unsafeRate',mean(allRows.terminated,'omitnan'), ...
   'failureRate',mean(allRows.status=="failed"),'attempted',height(allRows));
  if n>0, a.mean=mean(y); a.std=std(y); a.median=median(y); end
  % Student-t intervals only with >=2 independent seeds; no extra toolbox required.
  if n>=2
   z=betaincinv(0.05,n/2-0.5,0.5); critical=sqrt((n-1)*(1-z)/z);
   half=critical*a.std/sqrt(n); a.ci95Low=a.mean-half; a.ci95High=a.mean+half;
  end
  rows=[rows;a]; %#ok<AGROW>
 end
end
result=struct2table(rows);
end
