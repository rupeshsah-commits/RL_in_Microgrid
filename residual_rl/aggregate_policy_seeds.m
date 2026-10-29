function summary = aggregate_policy_seeds(reports,c)
% Average disturbance seeds within policy first; confidence interval across policies.
T=vertcat(reports{:}); rows=struct([]);
if isempty(T), summary=table(); return; end
groups=unique(T(:,{'scenario','controller'}),'rows');
metrics={'frequencyIAE','frequencyPeakHz','voltageIAE','voltagePeakPU', ...
 'activeSharingRMSE','reactiveSharingRMSE','residualNormalizedRMS'};
for g=1:height(groups)
 subset=T(T.scenario==groups.scenario(g)&T.controller==groups.controller(g),:);
 policies=unique(subset.policySeed);
 for j=1:numel(metrics)
  y=nan(numel(policies),1);
  for k=1:numel(policies)
   z=subset(subset.policySeed==policies(k),:);
   % A failed disturbance is not silently dropped from its policy mean.
   if all(z.status=="passed") && all(isfinite(z.(metrics{j})))
    y(k)=mean(z.(metrics{j}));
   end
  end
  y=y(isfinite(y)); n=numel(y);
  a=struct('scenario',groups.scenario(g),'controller',groups.controller(g), ...
   'metric',string(metrics{j}),'validPolicySeeds',n,'attemptedPolicySeeds',numel(policies), ...
   'mean',NaN,'std',NaN,'median',NaN,'ci95Low',NaN,'ci95High',NaN);
  if n>0, a.mean=mean(y); a.std=std(y); a.median=median(y); end
  if n>=2
   b=betaincinv(0.05,(n-1)/2,0.5); critical=sqrt((n-1)*(1-b)/b);
   half=critical*a.std/sqrt(n); a.ci95Low=a.mean-half; a.ci95High=a.mean+half;
  end
  rows=[rows;a]; %#ok<AGROW>
 end
end
summary=struct2table(rows);
folder=fullfile(c.results,'tables'); if ~isfolder(folder), mkdir(folder); end
writetable(summary,fullfile(folder,'independent_policy_seed_summary.csv'));
save(fullfile(folder,'independent_policy_seed_summary.mat'),'summary','T','c');
end
