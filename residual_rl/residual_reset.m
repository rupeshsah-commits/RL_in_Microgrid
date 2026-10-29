function in = residual_reset(in,c,loadScale)
% Reset is a fresh simulation; FastRestart off resets plant, delays and agent.
% Training varies switched Load 5 active power; evaluation supplies fixed scales.
if nargin < 3
    loadScale = c.trainLoadRange(1) + diff(c.trainLoadRange)*rand;
end
assert(isscalar(loadScale) && isfinite(loadScale) && loadScale > 0);
in = in.setModelParameter('StopTime',num2str(c.stopTime), ...
    'FastRestart','off','LoadInitialState','off');
in = in.setBlockParameter([in.ModelName '/Load 5'], ...
    'ActivePower',sprintf('%.17g',20e3*loadScale));
end
