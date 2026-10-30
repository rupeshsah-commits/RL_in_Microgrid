# Troubleshooting

MATLAB execution has not been performed in the cloud. Start from the first local
error and its complete stack; do not bypass assertions to label validation passed.

- Checksum mismatch: verify the exact case-sensitive source filename and recover
  the unmodified file from Git. Do not change the expected hash to bless an unknown
  local model; a different plant requires a fresh audit and mapping.
- Mapping failure: inspect `generated/signal_mapping_report.mat`, model hierarchy,
  transform mask, controller signs and existing gain connections. The builder fails
  before wiring an unverified path. Never substitute a similarly named signal.
- Missing MGLib: resolve the original library reference locally using your project's
  legitimate library files and MATLAB path. Do not replace dq-to-abc with an
  unverified transform or change modulation gains to hide the failure.
- Installed Reinforcement Learning Toolbox but the old product-group-5 check
  returns zero: the old gate incorrectly treated a feature-name query as definitive
  product unavailability. Update the project and rerun RUN_ME_FIRST. The new check
  distinguishes installed products, advisory feature hints, accessible APIs and
  actual construction of a small default TD3 agent. A zero hint alone no longer
  aborts setup. Real constructor failures still stop setup with their original cause.
  Construction is not training or full licence/Simulink validation; later operations
  remain required. Do not delete the gate or force licence hints to true.
- Missing installed product or real constructor failure: use the named product/API
  and original error in the diagnostic to check the local installation/path or
  normal product-access configuration. No passwords, university credentials,
  licence keys or tokens belong in this project. Setup prints product names,
  versions and releases from the `ver` return value, not its licence-number header.
- TD3 option/API errors: this code targets R2025a. Use the local `doc` for the exact
  failing RL option. Keep actor 42x1→8x1, two independent critics, agent sample time
  and plant-side safety contract unchanged. Static parsing cannot validate toolbox APIs.
- Model already loaded: close the generated model (preserving intentional edits)
  before rebuilding. Original validation refuses to close a preloaded source model
  so it cannot discard unsaved user edits.
- Zero-equivalence failure: inspect per-channel maximum/RMS deviations, solver
  settings, sample grids, original-vs-corrected mode and actual logs. Compare original
  only to generated `original` mode. Corrected voltage restoration is expected to
  change the plant response and cannot be called original-equivalent.
- Baseline trips at 0.5 s: inspect real startup traces and nominal voltage definition;
  determine whether startup is still transient. Changing protection timing/thresholds
  is a documented experimental decision, not a silent way to pass tests.
- Full-training flag: default refusal is intentional. Review physical bases and
  allowFullTraining. A smoke checkpoint is not a publishable trained controller.
- Resume signature mismatch: restore the original experiment config or retrain.
  Do not evaluate different reward/action semantics under the same experiment label.
- Very slow training: 2 microsecond electrical dynamics dominate cost. Reduce episode
  count for diagnosis, not step accuracy without a convergence study. No parallel
  training pool is launched automatically.
- Safety fallback may jump to zero and exceed nominal slew. This is deliberate;
  report emergency events separately from ordinary rate/smoothing interventions.

- Nominal-state unit comparisons on R2025a: converting `2*pi*60` back to Hz may
  leave an error of about 7e-15 Hz, giving a normalized observation near -3.6e-14
  and a squared cost near 1.3e-27. Exact-zero comparisons in the old observation,
  perfect-reward and isolated-objective tests rejected normal floating-point
  roundoff. Updated comparisons derive absolute tolerances from double-precision
  spacing, normalization, squaring and reward weighting. Production arithmetic,
  exact fallback zeros, safety thresholds and model-equivalence limits are unchanged.
  Update the project and rerun RUN_ME_FIRST; do not clamp small physical errors
  to zero or remove assertions. The later mock licence-hint lines in unit-test
  output are controlled test fixtures, not fresh findings about your installation.
