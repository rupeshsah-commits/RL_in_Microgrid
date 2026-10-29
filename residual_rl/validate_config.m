function validate_config(c)
assert(c.Ts>0 && c.plantTs>0 && abs(c.Ts/c.plantTs-round(c.Ts/c.plantTs))<1e-6);
assert(c.stopTime>c.eventRange(2) && c.warmup>=0 && c.warmup<c.eventRange(1));
assert(isequal(size(c.Prated),[4 1]) && all(isfinite(c.Prated)&c.Prated>0));
assert(isequal(size(c.Qrated),[4 1]) && all(isfinite(c.Qrated)&c.Qrated>0));
assert(isequal(size(c.limits),[8 1]) && all(isfinite(c.limits)&c.limits>0));
assert(isequal(size(c.slew),[8 1]) && all(isfinite(c.slew)&c.slew>0));
assert(numel(c.rewardWeights)==7 && all(isfinite(c.rewardWeights)&c.rewardWeights>=0));
assert(all(isfinite(c.mp)&c.mp>0) && numel(c.mp)==4);
assert(all(isfinite(c.nq)&c.nq>0) && numel(c.nq)==4);
assert(c.secondaryGain==5 && c.f0==60 && abs(c.omega0-2*pi*c.f0)<1e-12);
assert(c.fScale>0 && c.vScale>0 && c.v0>0 && isfinite(c.v0));
assert(c.kV>=0 && c.kQshare>=0 && c.kPshare>=0);
assert(isequal(c.adjacency,[0 1 0 1;1 0 1 0;0 1 0 1;1 0 1 0]));
assert(isequal(c.pin,[1;0;0;0]));
assert(c.obsDim==42 && c.smoothingTau>=0 && c.priorityMax>=1);
assert(ismember(c.controllerVariant,{'original','corrected','primary'}));
assert(isempty(intersect(c.trainSeeds,c.validationSeeds)));
assert(isempty(intersect(c.trainSeeds,c.testSeeds)));
assert(isempty(intersect(c.validationSeeds,c.testSeeds)));
assert(c.curriculumStage>=1 && c.curriculumStage<=3);
end
