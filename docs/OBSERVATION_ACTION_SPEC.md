# Observation/action contract

Raw measurement vector is 20x1:
`[omega1:4; Vd1:4; P1:4; Q1:4; Vq1:4]`, from the exact map in MODEL_AUDIT.
True sampled measurements drive reward and hard safety. Only policy observations
receive experimental noise and communication delay. No future event time is
provided to the actor. The model is not proven fully observable: switching states
and delayed measurement history are not all exposed; TD3 uses a Markov-relevant
approximation, not a claim of a complete physical Markov state.

| Observation indices | Quantity | Normalization |
|---|---|---|
| 1–4 | signed oscillator frequency errors (Hz) | divide by 0.2 Hz |
| 5–8 | dq magnitude voltage errors (phase-peak V) | divide by 0.02*V0 |
| 9–12 | filtered active powers (W) | local Prated study base |
| 13–16 | filtered reactive powers (var) | local Qrated study base |
| 17–20 | active sharing disagreement | Ppu_i - mean(Ppu) |
| 21–24 | reactive sharing disagreement | Qpu_i - mean(Qpu) |
| 25–32 | physical applied residuals | divide by eight physical bounds |
| 33–36 | physical frequency-secondary corrections | divide by 2*pi*3 |
| 37–40 | physical voltage-secondary corrections | divide by 0.10*V0 |
| 41–42 | bounded frequency/voltage priorities | 1–4 (not centered) |

All observations are double, 42x1, clipped to [-20,20]; nonfinite elements are
sanitized to zero for the actor while the unsanitized truth still triggers safety.
Previous-action and secondary-state components support slew/integrator dynamics.

The action specification is double 8x1 in [-1,1]. Indices 1–4 map to frequency
corrections ±0.2 Hz, converted to rad/s for insertion. Indices 5–8 map to voltage
corrections ±0.02*338.8460811 V. Saturation and fallback are outside the actor.
Observation/action specs are in `residual_specs.m`. Agent sample time is 0.02 s;
truth/secondary states use explicit zero-order holds and a digital clock. The
original electrical model uses 2 microsecond powergui sampling.

Logs include true/agent measurements, requested action, applied physical residual,
previous residual, physical secondary states, scalar reward, logical scalar done,
seven costs plus two priorities, and constraint-intervention samples. The RL Agent
block is `Residual_RL_Load_Changes_AC_Droop_four_inverter/Residual_RL_Interface/Agent`
for corrected mode. Without an available agent variable the builder places a named
zero-action placeholder; environment creation replaces it and checks that it is
resolved. Model variants have explicit suffixes; never guess a path from an old model.
