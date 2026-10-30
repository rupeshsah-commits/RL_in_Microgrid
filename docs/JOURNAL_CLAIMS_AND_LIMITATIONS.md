# Claims and limitations

Implemented: an auditable generated-copy workflow, corrected conventional voltage
restoration, bounded online residual interface, multi-objective TD3 environment,
state-dependent priorities, staged scenarios, evaluation/ablation and packaging code.
Statically checked: archive identity/topology/XML, source syntax and source-file
preservation. NOT RUN: compilation, environment validation, zero equivalence,
smoke/full training, evaluation or any performance comparison for this revision.
The user reported a return value from an earlier builder; that is not evidence for
current numerical validation. No generated binary SLX or trained policy is fabricated.

Do not claim frequency/voltage restoration, better sharing, convergence, stability,
robustness or novelty as demonstrated results. Literature novelty requires an
independent literature review. Corrected conventional control is a distinct baseline,
not a hidden RL benefit. Verify original Q sign, external MGLib, actual measurement
calibration, voltage balance, hardware ratings, inner-loop inherited sample times,
protection/capability envelopes and appropriate startup limits locally.

The controller observes frequency command, not a PLL sensor. Dq magnitude represents
phase peak under balanced conditions; unbalance/harmonics require a separate metric.
Study bases are assumptions; sharing RMSE is meaningful only relative to documented
ratings or declared equal-capacity assumptions. Raw semiconductor current/thermal
constraints are not added merely by bounding residual references.

Adaptive objective weighting is a bounded heuristic, not constrained-MDP feasibility
or Lyapunov certification. Slew/saturation do not prove physical safety. The policy
is not proven fully Markov; communication delay and hidden plant switching states
can introduce partial observability. Simulation wall time is not inference latency.
A zero residual does not make corrected conventional control identical to the original.

Checkpoint resume retains policy/replay/RNG metadata but does not restore the exact
in-progress simulator trajectory or original training-statistic history. Full-run
opt-ins and training logs must be reviewed before publication. Static code generation
cannot establish release-specific MATLAB RL API compatibility.
