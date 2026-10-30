# Controller equations and constraints

All equations below describe implementation, not a validated stability result.
Primary and inner controllers remain active; RL never writes their gains.

Let A be the undirected ring adjacency (1–2–3–4–1), d_i its row sum and
b=[1,0,0,0]. P and Q are output-side filtered powers using H(s)=60/(s+60).
Original primary commands are:

`omega_primary_i = 2*pi*60 - 1e-4*P_i` (rad/s),
`V_primary_i = 338.8460811 - 1e-4*Q_i` (dq volts).

Original frequency state derivative:
`dot(zW_i)=b_i*(omega0-omega_i)+sum_j Aij*(omega_j-omega_i)
 +1e-4*sum_j Aij*(P_j-P_i)`.
Original voltage state derivative:
`dot(zV_i)=1e-4*sum_j Aij*(Q_j-Q_i)`.
The physical secondary corrections are `5*zW_i` and `5*zV_i`. For example DG1
uses neighbors 2 and 4, DG2 neighbors 1 and 3, DG3 neighbors 2 and 4, DG4 neighbors
1 and 3. Only DG1 has the absolute frequency reference term. The voltage terms
never use their Vd input arguments. The JSON audit retains the exact MATLAB code.

## Corrected conventional mode, separately testable with RL disabled

Define Ppu_i=P_i/Prated_i, Qpu_i=Q_i/Qrated_i, Vpu_i=hypot(Vd_i,Vq_i)/V0.
Prated/Qrated are explicitly labeled study bases until confirmed as ratings.
Keep frequency consensus topology, replacing power differences by
`Pbase*(Ppu_j-Ppu_i)`. For equal default bases this is the exact original power
term. Primary m_p and n_q are fixed configuration coefficients, not agent actions.

Reuse the existing voltage integrator; do not add another secondary integrator:
`g_i = kV*(1-Vpu_i) + kQshare*sum_j Aij*(Qpu_j-Qpu_i)` in V/s.
`dot(zV_i)=g_i/secondaryGain` unless conditional integration blocks outward drive.
`deltaVsec_i=secondaryGain*zV_i`, limited to ±0.10*V0.
Defaults: secondaryGain=5, kV=5 V/s per pu error,
kQshare=25 V/s per pu disagreement (matching original 5*1e-4*Qbase for equal bases).
Conventional frequency corrections are limited to ±2*pi*3 rad/s.

Limited continuous integrators and conditional voltage integration prevent state
windup: at an upper/lower bound, outward derivative is zero, while inward drive
is allowed. Secondary saturation is applied to physical correction units before
residual addition. Inner PI/PWM limits are preserved without retuning. The
`primary` benchmark zeros secondary gain outputs; it is labeled separately.

## Residual action and constraints

For normalized a in [-1,1]^8, physical target L.*clip(a,-1,1). L is
[2*pi*0.2 rad/s (four); 0.02*V0 volts (four)]. Frequency conversion is explicit:
normalized residual → Hz bound → rad/s reference correction. Voltage uses phase-peak
dq volts, not RMS. These are small initial limits (0.33% nominal frequency and 2%
nominal voltage), chosen for a conservative experiment, not proven safe hardware limits.

First-order smoothing: alpha=Ts/(tau+Ts), smooth=old+alpha*(target-old), tau=0.04 s.
Slew: next=old+clip(smooth-old,-rate*Ts,rate*Ts); clip next again to ±L.
Rates are 0.5 Hz/s and 5% V0/s. One sample of physical-action memory breaks the
policy/plant loop; the applied correction is part of observation state.
Manual bypass, startup, invalid data or unsafe measurements force zero residual;
emergency fallback takes priority over nominal slew. A final enable/finite-memory bypass never forwards invalid stored output.
Invalid commands or unsafe measurements produce zero at the next actuator sample
(within Ts=20 ms); current raw action never bypasses the validated delay. A delayed
raw-command flag terminates invalid-action episodes at that next sample. This
causality boundary avoids a direct policy/measurement algebraic loop.

`omega_cmd=omega_conventional+deltaOmega_safe`;
`Vd_cmd=V_conventional+deltaV_safe`.
Injection is after `Sum2`/`Sum6`, before oscillator/inner voltage reference routing.
No injection touches PWM, measured signals, plant parameters, gains or protections.

## Reward and interpretable tradeoff

Seven normalized costs: mean squared frequency error/fScale, voltage error/vScale,
variance of Ppu, variance of Qpu, normalized applied action, normalized applied
sample-to-sample change, and soft-limit excess. Default weights are
[1,1,0.2,0.2,0.02,0.01,1]. Sample reward is `-Ts*sum(weights.*costs)`;
startup reward is zero. Applied actions, rather than requested commands, enter cost.
Soft penalties start at 0.5 Hz, 5% voltage and 1.2 study pu power.
Hard termination: after startup >3 Hz or >20% voltage error; any nonfinite input
also terminates with a penalty of 100. Power soft limits are study penalties,
not manufacturer capability envelopes.

For frequency and voltage only, priority multiplier is
`1+(priorityMax-1)*clip(proximity,0,1)^2`, priorityMax=4; proximity is maximum
local error divided by its soft threshold. Sharing and safety weights cannot be
disabled by the agent. Both multipliers and all seven unweighted costs are logged.
Fixed-priority ablation sets multipliers to one. The action-rate cost uses sample
differences, not derivatives; its normalization and Ts are fixed across comparisons.
