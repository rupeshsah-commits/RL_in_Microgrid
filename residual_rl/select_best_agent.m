function bestFile = select_best_agent(c)
% Best is training-reward selection, NOT evidence of best held-out performance.
files=dir(fullfile(c.results,'checkpoints','full_*','best_agent.mat'));
assert(~isempty(files),'No best-agent checkpoint available.');
[~,i]=max([files.datenum]); bestFile=fullfile(files(i).folder,files(i).name);
end
