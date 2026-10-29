function plot_residual_results(out,c,s,label,folder)
[t,x]=residual_series(out,'residual_x',20); [tu,u]=residual_series(out,'residual_u',8);
[tr,parts]=residual_series(out,'residual_components',9);
if ~isfolder(folder), mkdir(folder); end
fig=figure('Visible','off','Color','w','Position',[50 50 1200 1000]);
cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
tiledlayout(4,2,'TileSpacing','compact');
y={x(:,1:4)/(2*pi),hypot(x(:,5:8),x(:,17:20)),x(:,9:12)./c.Prated.', ...
 x(:,13:16)./c.Qrated.',u(:,1:4)/(2*pi),u(:,5:8),parts(:,1:7),parts(:,8:9)};
units={'Frequency command (Hz)','Voltage magnitude (phase peak V)','Active power (study pu)', ...
 'Reactive power (study pu)','Residual frequency (Hz)','Residual voltage (V)', ...
 'Unweighted reward costs','Priority multipliers'};
for i=1:8
 nexttile;
 if i<=4, plot(t,y{i},'LineWidth',1.2);
 elseif i<=6, plot(tu,y{i},'LineWidth',1.2);
 else, plot(tr,y{i},'LineWidth',1.2); end
 grid on; xlabel('Time (s)'); ylabel(units{i}); set(gca,'FontSize',11);
 for event=s.switchTimes(:).', xline(event,'--k'); end
 if i<=6, legend('DG1','DG2','DG3','DG4','Location','best'); end
 if i==7, legend('f','V','Pshare','Qshare','u','du','soft','Location','best'); end
 if i==8, legend('frequency','voltage','Location','best'); end
end
sgtitle(strrep(label,'_',' '));
exportgraphics(fig,fullfile(folder,[label '.png']),'Resolution',300);
exportgraphics(fig,fullfile(folder,[label '.pdf']),'ContentType','vector');
end
