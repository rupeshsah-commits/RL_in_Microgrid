# Local execution guide

1. Download the branch or project ZIP, extract it, and open licensed MATLAB R2025a
   (models saved in Update 1). Set Current Folder to the extracted repository root.
2. Run `RUN_ME_FIRST`. It adds project-relative paths, prints release/products,
   checks installed products and advisory licence hints without printing the licence-number
   header, probes a small TD3 constructor without training, verifies SHA-256,
   checks mappings, builds separate models, compiles, runs original/zero equivalence
   and a bounded probe, and validates the RL environment. No training starts.
3. Inspect `results/logs/setup_*.txt`, `setup_report.mat`, `validation.mat` and
   `zero_action_equivalence.mat`. Fix the first error using TROUBLESHOOTING.
4. Run `RUN_SMOKE_TEST`: exactly two episodes, stage 1, no GUI plot. It may still
   be slow: 15 s / 2 microseconds = 7.5 million electrical steps per episode.
5. Review `residual_config.m`. Confirm/replace study normalization bases; rerun
   RUN_ME_FIRST if control parameters change; explicitly
   set `allowFullTraining=true` and `ratingsConfirmed=true` in your experiment
   config or in RUN_TRAINING after review. These are scientific setup flags, not
   credential requests. Never silently infer hardware ratings from source labels.
6. Run `RUN_TRAINING`. Full mode runs three curriculum stages, 100 episodes each
   by default, with checkpoints every five episodes and TD3 replay-buffer retention.
7. Run `RUN_EVALUATION` to evaluate the most recent best training-reward agent, or
   explicitly call `evaluate_residual(agentPath,c)` for a chosen checkpoint.
   Default evaluation is 120 full simulations per policy (8 scenarios × 3 disturbance
   seeds × 5 controllers). For a diagnostic subset, explicitly call
   `c=residual_config(); c.evalScenarios={'nominal'}; c.testSeeds=c.testSeeds(1);`
   then `evaluate_residual(selectedAgent,c)`. Label this subset, not full evaluation.
8. Find timestamped evaluation logs, CSV tables, summary statistics and PNG/PDF
   figures under `results/evaluation_*/`. Training outputs are under
   `results/checkpoints/`. Nothing there is committed by default.

Exact batch commands, from the repository root:

```sh
matlab -batch "RUN_ME_FIRST"
matlab -batch "RUN_SMOKE_TEST"
# Deliberately enable the reviewed full-training flags before this command:
matlab -batch "RUN_TRAINING"
matlab -batch "RUN_EVALUATION"
```

Explicit resume with reviewed configuration:

```matlab
addpath('residual_rl')
c=residual_config(); c.allowFullTraining=true; c.ratingsConfirmed=true;
continue_training('results/checkpoints/ACTUAL_RUN/residual_agent.mat',c);
```

Resume preserves compatible policy/replay-buffer/RNG state where saved; it starts
new training statistics/batches and replays the curriculum, not an exact simulator
continuation of the interrupted episode. Ctrl+C may bypass MATLAB catch handling;
periodic complete checkpoints remain the recovery mechanism. Do not use legacy
fault checkpoints. No full training runs automatically during setup or build.

Additional explicit runtime tests:

```matlab
addpath('residual_rl')
results=runtests('residual_rl/tests/test_model_runtime.m'); assertSuccess(results)
```

Standalone builder (zero placeholder until environment creation):
`addpath('residual_rl'); build_residual_model`.
The main agent model has the requested exact filename under `generated/`; auxiliary
zero/disabled/probe/original/primary models have descriptive suffixes. Close generated
model windows before rebuilding to preserve unsaved local edits. Never save the
original source model from a validation session. Builder idempotence starts each
copy from the original; it does not append blocks to an old generated model.
