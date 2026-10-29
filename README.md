# Online residual RL for microgrid frequency and voltage

**MATLAB/Simulink runtime validation is PENDING. MATLAB was neither installed nor
run in the cloud environment.** Static checks do not establish that model
compilation, simulation, training or control performance works.

This project retains the original four-inverter electrical plant, conventional
P–frequency / Q–voltage droop loops, consensus secondary controllers and their
integrators. A new centralized DDPG policy supplies eight small online residual
corrections. It does not replace the conventional controllers or tune their gains.

The original file is named **`Load_Changes_AC_Droop_four_inverter.slx`** (case
sensitive), not `Load_changes_...`. It is unchanged. Its SHA-256 is
`3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123`.
The other original fault-scenario SLX is also retained unchanged.

## Files and review findings

- `residual_rl/residual_config.m`: timing, bounds, scales, load scenarios, paths.
- `build_residual_model.m`: constructs separate zero, probe and agent models.
- `residual_safety.m`: amplitude and slew limits, startup gate, invalid-input fallback.
- `residual_reward.m`: observation, sampled cost and termination.
- `residual_reset.m`: fresh plant/delay state and switched-load randomization.
- `residual_agent.m`, `train_residual.m`: actor/critic and multi-step online learning.
- `evaluate_residual.m`, `residual_metrics.m`: deterministic paired baseline comparison.
- `validate_residual.m`, `tests/test_residual.m`: local runtime gates and unit tests.
- `docs/static_model_review.json`: extracted topology, equations and archive checks.
- `tools/static_review.py`: repeatable static archive inspection.
- `tools/package_project.py`: ZIP with original models, all source and checksums.

There were no existing residual-RL files in the inspected checkout. The three root
MATLAB scripts are legacy episode-level gain tuning for the fault model, using one
action and a full 15-second simulation per episode. They remain separate. The
legacy evaluation now explicitly disables exploration and loads its model before
assigning learned gains, because its PreLoadFcn resets gains on model loading.

## Local commands (MATLAB R2025a Update 1)

Install/use MATLAB with Simulink, Simscape, Simscape Electrical **Specialized
Power Systems**, Reinforcement Learning Toolbox and Deep Learning Toolbox. The
models contain `MGLib/Subsystem` references; check their actual resolution locally.
No runtime or toolbox availability has been verified here. Prefer the saved
release; newer-release compatibility is untested.

From the repository root in a shell, run these commands exactly:

```sh
python3 tools/static_review.py
matlab -batch "addpath('residual_rl'); disp(version); ver; validate_residual"
matlab -batch "addpath('residual_rl'); train_residual"
```

The first MATLAB command runs unit tests, compiles the generated models, runs
15-second zero and nonzero probe simulations, checks action bounds and slew,
compares zero residual with the original model, and validates the RL environment.
Do not proceed to training if it fails. Inspect the first error; do not remove
assertions or overwrite the original SLX to make it pass. This gate may reveal
unresolved library links, toolbox/API incompatibilities, sample-time issues,
baseline protection thresholds or other model problems that static review cannot
resolve.

After training, evaluate the most recently saved agent with:

```sh
matlab -batch "addpath('residual_rl'); d=dir('results/training_*/residual_agent.mat'); assert(~isempty(d),'No trained agent found'); [~,i]=max([d.datenum]); evaluate_residual(fullfile(d(i).folder,d(i).name));"
```

For interactive MATLAB:

```matlab
cd('/absolute/path/to/RL_in_Microgrid')
addpath('residual_rl')
validate_residual
train_residual
% Use the actual path printed by training:
evaluate_residual('results/training_YYYYMMDD_HHMMSS_SSS/residual_agent.mat');
```

Generated models and caches live in ignored `generated/`. Model source is copied
there before any edits. `zero` supplies zero actions, `probe` supplies a fixed
normalized 0.1 action for connectivity checks, and `agent` uses the RL Agent block.
The MATLAB builder must run locally: no generated SLX is included or claimed to
exist before that command runs. Generated model windows must be closed before a
rebuild. Models are closed without saving by validation/evaluation cleanup.

Training has a fixed RNG seed, no GUI progress plot and up to 100 episodes of
750 steps. Simulating switching electronics may be expensive; first run the
validation gate. Checkpoints and the final agent are stored in a unique results
directory. Evaluation saves raw simulations, configuration and `comparison.csv`. Simulation
failures are recorded as failed rows with NaN metrics and the error message; they
are never counted as passing comparisons. Model-generation errors still stop the
workflow for diagnosis.

## Control interface and timing

For every DG, insertion is after `DGn/Gain` or `DGn/Gain9`, before the positive
second input of `Sum2` or `Sum6`. These existing gains are 5. Their outputs remain
connected to the new summing blocks; the droop paths and secondary integrators
are not removed or reset by policy actions. Residuals are added **after** the gain,
so no hidden factor of five scales their physical bounds.

| Quantity | Definition / default |
|---|---|
| Measured frequency | `w1..w4` rad/s divided by `2*pi`; nominal 60 Hz |
| Measured voltage | `Vd1..Vd4`, signed synchronous dq d-axis volts |
| Voltage reference | 338.8460811 V from the original model; not RMS voltage |
| Action | 4 frequency then 4 voltage normalized residuals in `[-1,1]` |
| Physical frequency bound | ±0.2 Hz, injected as ±`2*pi*0.2` rad/s |
| Physical voltage bound | ±2% of the dq voltage reference |
| Slew | 0.5 Hz/s and 5% reference voltage/s |
| Policy/sample period | 0.02 seconds |
| Startup residual gate | zero before 0.5 seconds |
| Observation | 4 normalized signed frequency errors, 4 normalized voltage errors, 8 applied normalized residuals |

Measurements use a zero-order hold. A physical-action Unit Delay, initialized to
zero each simulation, breaks the policy/plant algebraic loop and adds one policy
sample of actuator delay. The guard limits the next applied action relative to
the current action. Invalid action/measurement values command zero for the next
actuator sample (this emergency fallback may violate the nominal slew limit).
Observations are finite and clipped to ±20; safety termination uses unclipped
measurements. This is a simulation research controller, not a certified safety
system or proof of stability.

The per-step reward is minus `Ts` times mean squared normalized frequency error
plus mean squared normalized voltage error plus 0.02 times mean squared applied
normalized residual. Reward is zero during startup. Nonfinite measurements or
action, or errors exceeding 3 Hz / 20% dq voltage after startup, set `isDone` and
incur a terminal penalty of 100. Reward penalizes the applied residual, not an
unrealized unbounded command. No improvement or stability result is claimed.

Reset disables Fast Restart and loading initial state, starting the plant,
action delay and policy episode fresh. Training uniformly varies `Load 5` active
power from 16–24 kW; the original breaker event at 6 seconds and existing plant
reference steps remain. Evaluation uses 16, 20 and 24 kW, matching RNG seeds for
conventional and residual runs and disabling exploration. These scenarios overlap
the training distribution; they are regression comparisons, not out-of-distribution
robustness evidence. Report frequency IAE/ITAE, peak Hz error, voltage IAE/peak per
unit, raw traces and any failed runs. The original conventional controller may
have steady-state droop errors; a fixed voltage target does not prove reactive
power sharing. Add power-sharing objectives only with a separately justified
experiment.

## Validation status and packaging

Verified in the cloud: original archive CRC, parsing of 42 XML entries, eight
injection connections with positive signs, measurement tags, nominal references,
load/event parameters, MATLAB source syntax using MISS_HIT 0.9.44, and unchanged
original model hashes. MATLAB unit tests, model generation/compilation, simulation,
zero-baseline equivalence, agent construction, training and performance evaluation
are all **pending local execution**.

To repeat static syntax checking without MATLAB:

```sh
python3 -m venv /tmp/microgrid-static
/tmp/microgrid-static/bin/pip install miss_hit==0.9.44
/tmp/microgrid-static/bin/mh_lint --brief residual_rl *.m
```

Build a portable source ZIP (excludes Git metadata, caches, generated outputs and
training results):

```sh
python3 tools/package_project.py --output /workspace/outputs/RL_in_Microgrid_residual_rl.zip
```

The ZIP includes both original SLX files, every project source/documentation file
and a SHA-256 manifest. It does not contain a trained policy or fabricated results.
