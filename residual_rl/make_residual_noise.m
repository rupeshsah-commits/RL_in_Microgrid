function noise = make_residual_noise(c,s)
t=(0:c.Ts:c.stopTime).';
g=RandStream('mt19937ar','Seed',s.seed);
scale=[repmat(c.omega0,4,1);repmat(c.v0,4,1);c.Prated;c.Qrated;repmat(c.v0,4,1)];
y=s.noiseFraction*randn(g,numel(t),20).*scale.';
noise=timeseries(y,t);
end
