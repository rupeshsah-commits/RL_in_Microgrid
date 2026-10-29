function c = residual_config()
% Units: omega rad/s; Vd dq volts (not RMS); normalized action in [-1,1].
root = fileparts(fileparts(mfilename('fullpath')));
c.root = root;
c.source = fullfile(root,'Load_Changes_AC_Droop_four_inverter.slx');
c.output = fullfile(root,'generated');
c.results = fullfile(root,'results');
c.Ts = 0.02;
c.stopTime = 15;
c.warmup = 0.5;
c.f0 = 60;
c.v0 = 338.8460811;
c.limits = [repmat(2*pi*0.2,4,1); repmat(0.02*c.v0,4,1)];
% Maximum physical slew per second: 0.5 Hz/s and 5 percent Vd/s.
c.slew = [repmat(2*pi*0.5,4,1); repmat(0.05*c.v0,4,1)];
c.fScale = 0.2; c.vScale = 0.02*c.v0;
c.tripHz = 3; c.tripVoltagePU = 0.2;
c.episodes = 100; c.seed = 42;
c.trainLoadRange = [0.8 1.2];
c.evalScales = [0.8 1.0 1.2];
c.evalSeeds = [101 202 303];
c.rewardWeights = [1 1 0.02]; % frequency, voltage, residual effort
c.terminalPenalty = 100;
end
