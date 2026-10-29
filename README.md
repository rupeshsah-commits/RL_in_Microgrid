**Validation status: MATLAB was unavailable in the cloud. Original model compilation,
generated model compilation, environment validation, zero-action equivalence,
smoke/full training and evaluation are all NOT RUN for this revision. Static checks
are reported separately. No generated SLX or successful performance result is fabricated.**

# Constraint-aware online residual RL for a four-inverter microgrid

The primary plant is `Load_Changes_AC_Droop_four_inverter.slx`. Its original bytes
remain unchanged. Conventional droop, consensus, inner control and physical limits
remain connected. The generated model adds eight small bounded online residual
reference corrections; RL does not tune gains or replace conventional control.
A separate corrected-conventional mode adds voltage restoration and secondary
anti-windup; exact-original mode remains available for fair equivalence tests.

## Start locally

Download/extract the ZIP or branch, open MATLAB R2025a, set Current Folder to the
repository root, then run:

```matlab
RUN_ME_FIRST
RUN_SMOKE_TEST
% Review config, confirm/replace study bases and explicitly opt in first:
RUN_TRAINING
RUN_EVALUATION
```

`RUN_ME_FIRST` stops before training. `RUN_SMOKE_TEST` uses two episodes. Full
training is disabled by default. Required products are MATLAB, Simulink, Simscape,
Simscape Electrical Specialized Power Systems, Reinforcement Learning Toolbox and
Deep Learning Toolbox. No credentials or secrets should be placed in this project.

Read [local execution](docs/LOCAL_EXECUTION_GUIDE.md) for exact batch commands,
reports, recovery and runtime test commands. Results go under ignored `results/`;
models/cache go under ignored `generated/`. The main generated model is
`Residual_RL_Load_Changes_AC_Droop_four_inverter.slx`, containing
`Residual_RL_Interface`. It is built locally from the source, never written over it.

## Research design and audit

- [Model audit, voltage definitions and exact signal paths](docs/MODEL_AUDIT.md)
- [Original/corrected conventional equations, limits and reward](docs/CONTROL_EQUATIONS.md)
- [42 observations, eight actions and logging contract](docs/OBSERVATION_ACTION_SPEC.md)
- [Experiments, baselines, curriculum, ablations and statistics](docs/EXPERIMENT_PROTOCOL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Claims and limitations](docs/JOURNAL_CLAIMS_AND_LIMITATIONS.md)

The archive's voltage convention is amplitude-invariant dq, corresponding to phase
peak when balanced. The reported 344 V trace is not present. `K_v_ref=0.5` is not
found in the archive. Hardware inverter ratings are not provided; equal study bases
are explicitly labeled, and full training requires their confirmation/replacement.
Frequency observations are oscillator commands, not independent PLL measurements.

TD3 uses separate critics, zero-initialized bounded actor output, replay warmup,
gradient clipping and checkpoints. Rewards include frequency, voltage, P/Q sharing,
action, action change and soft-limit costs. Interpretable bounded priorities increase
restoration emphasis near soft boundaries. Guarded physical corrections have explicit
magnitude/slew limits, smoothing, enable/bypass and nonfinite/unsafe fallback.

The old fault SLX and root fault/gain-tuning scripts are legacy, separate workflows.
The new code is under `residual_rl/`; tests are under `residual_rl/tests/`.

## Static checks and source package

```sh
python3 tools/static_review.py --report docs/static_model_review.json
python3 tools/audit_model.py
python3 tools/check_project.py
python3 -m venv /tmp/microgrid-static
/tmp/microgrid-static/bin/pip install miss_hit==0.9.44
/tmp/microgrid-static/bin/mh_lint --brief residual_rl RUN_*.m *.m
python3 tools/package_project.py --output distributions/RL_in_Microgrid_Residual_RL_Project.zip
```

These commands do not run MATLAB. The package contains original SLX files, source,
documentation, tests and a SHA-256 manifest, excluding credentials, caches and training
artifacts. No generated SLX is included unless genuinely produced locally and
explicitly requested from the packager. See `docs/STATIC_CHECKS.md` for recorded
static evidence and runtime checks still pending.
