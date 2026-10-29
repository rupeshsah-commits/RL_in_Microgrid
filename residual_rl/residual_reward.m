function [obs,reward,done] = residual_reward(x,u,t,p)
%#codegen
% p=[f0;v0;fScale;vScale;tripHz;tripVpu;warmup;Ts;weights(3);penalty;limits(8)]
f = x(1:4)/(2*pi);
v = x(5:8);
invalid = any(~isfinite(x)) || any(~isfinite(u));
ef = (f-p(1))/p(3);
ev = (v-p(2))/p(4);
done = invalid || (t >= p(7) && ...
    (any(abs(f-p(1)) > p(5)) || any(abs(v/p(2)-1) > p(6))));
obs = [ef;ev;u./p(13:20)];
obs(~isfinite(obs)) = 0;
obs = min(max(obs,-20),20);
cost = p(9)*mean(ef.^2) + p(10)*mean(ev.^2) + ...
    p(11)*mean((u./p(13:20)).^2);
if invalid || ~isfinite(cost)
    cost = 0;
    done = true;
end
reward = -p(8)*cost;
if t < p(7)
    reward = 0;
end
if done
    reward = reward-p(12);
end
end
