# Static verification record

MATLAB/Simulink was not installed or executed in the cloud. Every MATLAB unit
and integration test is NOT RUN. No compiled SLX or trained policy is included.
The earlier user-reported builder return value is not validation of this revision.

Executed in the cloud:

| Check | Result / evidence |
|---|---|
| Original load SLX SHA-256 | PASS: `3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123` |
| Original fault SLX SHA-256 | PASS: `1710a983a0748f55290301f55f6958e6149d033e8e6ba6bc3074113fbf7510b0` |
| ZIP CRC / XML | PASS: 53 entries; all 42 XML documents parsed |
| Model inventory | PASS: 1,041 archived blocks in `model_inventory.json` |
| Controller signal map | Static connections, gains, signs and tags checked; runtime map gate remains NOT RUN |
| MATLAB source syntax | PASS: MISS_HIT 0.9.44; 49 MATLAB files |
| Embedded MATLAB Function templates | PASS: five extracted templates parsed; constant struct typing NOT checked |
| Python source syntax | PASS: `python3 -m py_compile tools/*.py` |
| Required-file inventory | PASS: `tools/check_project.py` |
| Duplicate source hashes | PASS: nonempty source files checked; distribution self-copies excluded |
| Absolute developer paths | PASS: bounded project-source scan |
| Potential secrets | PASS: bounded credential-pattern scan; not proof that every possible secret format is absent |
| Git whitespace/conflict checks | PASS: `git diff --check` |
| Project ZIP | CRC, duplicate names and every manifest SHA-256 checked by the packager |

The source ZIP records its source commit before the packaging-only commit. It
excludes itself, Git metadata, generated models/cache, results and training artifacts.
No generated SLX appears because none was built by MATLAB in this environment.
The copy in the external outputs directory is byte-identical to the distribution ZIP.

Local runtime commands, all still pending:

```matlab
RUN_ME_FIRST       % original/generated compilation, interface, zero equivalence
RUN_SMOKE_TEST     % two episodes only
% Review bases and explicitly enable full training before the next command:
RUN_TRAINING
RUN_EVALUATION
```

Additional model tests: `runtests('residual_rl/tests/test_model_runtime.m')`.
A setup report says PASS only after the actual local checks return successfully.
No result table, graph or control-performance claim is substituted for missing runtime evidence.
