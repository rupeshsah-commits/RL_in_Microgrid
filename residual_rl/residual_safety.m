function u = residual_safety(a, previous, x, t, limits, slew, Ts, warmup, enabled)
%#codegen
% Independent plant-side guard; invalid input commands zero at the next actuator sample.
u = zeros(8,1);
if ~enabled || t < warmup || any(~isfinite(a)) || ...
        any(~isfinite(previous)) || any(~isfinite(x))
    return
end
target = min(max(a(:),-1),1).*limits;
step = slew*Ts;
u = previous + min(max(target-previous,-step),step);
u = min(max(u,-limits),limits);
end
