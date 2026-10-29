# Experiment protocol

This is a proposed executable protocol. No experimental results exist yet.

## Baseline separation

Compare original droop+secondary, corrected conventional (disabled residual),
corrected zero residual, corrected+trained residual, and primary-only. Identical
scenario events, initial states, solver settings and random streams are used for
each comparison. Zero equivalence covers original vs original-disabled,
original-disabled vs original-zero, and corrected-disabled vs corrected-zero.
Correction benefits must not be attributed to RL. The primary benchmark disables
secondary output gains in a copy only; it is not the original conventional baseline.

## Curriculum and held-out testing

Stage 1: fixed 20 kW modest step at 6 s, no noise/delay/uncertainty.
Stage 2: 16–24 kW steps, 0–5 kvar reactive composition, event time 5–7 s.
Stage 3: also ≤0.2% nominal-scale Gaussian observation noise, 0–2 communication
samples delay (0–40 ms), ±3% DG L1 inductance uncertainty. Other physical/inner
controller parameters are unchanged. All randomization is per episode, not an
agent command. Stage 4 is held-out evaluation: nominal, 28 kW unseen increase,
28 kW removal with initially closed breaker, 8 kvar variation, 0.3% noise,
60 ms delay, +6% inductance, and an unseen combination. Same seed gives the same
noise/event realization for every controller; policy measurements alone are delayed
and noisy. Conventional loops still use their existing measurements.

Training seeds 42–44, validation 101–103, test 901–903 are disjoint. Evaluation
loops over all three test disturbance seeds. A single train_residual call trains
one policy seed; `run_training_seeds` explicitly trains the three independent policy
seeds. Disturbance-seed uncertainty alone is not policy-training uncertainty. For a
journal study, repeat evaluation for every independent trained policy and retain
both seed IDs. No test-set tuning or selecting the best test score.

## Selection, checkpoints and costs

TD3 is selected for continuous bounded action, twin critics, delayed policy updates
and target smoothing. DDPG is legacy. Actor starts at zero output. Gradient clipping,
warm-start replay samples, bounded exploration and retained replay buffers are
configured. Best-agent selection is mean reward of a completed training batch; it
is not a claim of best validation performance. Use validation-only selection for
final journal experiments and freeze it before test evaluation.

Metrics include frequency nadir/zenith, maximum error, IAE/ISE/ITAE, voltage
IAE/ISE/ITAE, settling after the final physical event, rating-base-normalized P/Q
sharing RMSE, action peak/RMS/slew, intervention samples and unsafe/termination
rates. Time-weighted integrals use episode time. Settling is the first sample after
the last violation of the stated band following the final event; no settled value
is reported as NaN. Frequency is the oscillator command, not independently measured
physical frequency. Decision inference time is NaN unless separately instrumented;
wall-clock simulation time is never substituted for inference latency.

Separate success, unsafe/incomplete simulation, and exceptions. Save every attempt,
including errors. Aggregate by scenario/controller with mean/std/median and Student-t
95% intervals across independent disturbance seeds (n≥2); small n and Gaussian/independence
assumptions limit these intervals. Report attempted/failed counts alongside summaries.
Unsettled/failed metrics are not zeros. Inspect raw traces and event markers.

## Ablations and tradeoffs

`run_ablations('plan',c)` saves a manifest only. Explicit `run_ablations('train',c)`
re-trains and evaluates separate policies for full objective, no voltage term, no
sharing terms, no action-rate cost, no slew/smoothing, and fixed objective weights.
A safety-free deployment variant is intentionally not provided: the no-slew/smoothing
ablation still retains mandatory magnitude, finite-value and unsafe-state fallback.
Voltage-cost ablation retains voltage soft/hard safety penalties; it removes only
the primary voltage-restoration objective. This constrained ablation tests rate/shaping protection without violating the
non-negotiable bounded residual interface. Do not label it complete removal of safety.

Frequency/voltage priorities vary continuously within [1,4] near soft boundaries;
sharing weights remain active. Log all priorities and costs. To study static Pareto
tradeoffs, `run_tradeoff_sweep` produces or trains a finite grid of frequency/voltage/
sharing weights; fixed and adaptive variants require separate training. All ablation
policies have configuration signatures preventing accidental cross-evaluation.
