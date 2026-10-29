function plot_baseline_overlay(runDir,c)
% Compare mean absolute four-DG restoration/sharing errors for identical scenarios.
files=dir(fullfile(runDir,'logs','*.mat')); groups=struct();
for k=1:numel(files)
 a=load(fullfile(files(k).folder,files(k).name),'s','cc','out','status');
 if ~strcmp(a.status,'passed'), continue; end
 key=matlab.lang.makeValidName(sprintf('%s_%d',a.s.name,a.s.seed));
 if ~isfield(groups,key), groups.(key)={}; end
 groups.(key){end+1}=files(k).name;
end
keys=fieldnames(groups);
for k=1:numel(keys)
 fig=figure('Visible','off','Color','w','Position',[50 50 1100 700]);
 cleanup=onCleanup(@() close(fig)); tiledlayout(2,2);
 entries=groups.(keys{k});
 for j=1:numel(entries)
  a=load(fullfile(runDir,'logs',entries{j}),'out','s','cc');
  [t,x]=residual_series(a.out,'residual_x',20);
  P=x(:,9:12)./c.Prated.'; Q=x(:,13:16)./c.Qrated.';
  values={mean(abs(x(:,1:4)/(2*pi)-c.f0),2), ...
   mean(abs(hypot(x(:,5:8),x(:,17:20))/c.v0-1),2), ...
   sqrt(mean((P-mean(P,2)).^2,2)),sqrt(mean((Q-mean(Q,2)).^2,2))};
  for panel=1:4
   nexttile(panel); hold on;
   plot(t,values{panel},'LineWidth',1.2,'DisplayName',strrep(entries{j},'_',' '));
  end
 end
 units={'Mean absolute frequency command error (Hz)','Mean voltage magnitude error (pu)', ...
 'Active sharing RMS disagreement (study pu)','Reactive sharing RMS disagreement (study pu)'};
 for panel=1:4
  nexttile(panel); grid on; xlabel('Time (s)'); ylabel(units{panel});
  set(gca,'FontSize',11); legend('Location','best','Interpreter','none');
  for event=a.s.switchTimes(:).', xline(event,'--k','HandleVisibility','off'); end
 end
 exportgraphics(fig,fullfile(runDir,'figures',['overlay_' keys{k} '.pdf']),'ContentType','vector');
 exportgraphics(fig,fullfile(runDir,'figures',['overlay_' keys{k} '.png']),'Resolution',300);
 clear cleanup
end
end
