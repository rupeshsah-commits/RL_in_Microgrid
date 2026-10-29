# Load-change model audit

**Static audit only. MATLAB/Simulink compilation and simulation are NOT RUN for this revision.**
The older builder reportedly returned a generated model name locally; that is not
compilation evidence for this revised workflow.

## Identity and architecture

Original: `Load_Changes_AC_Droop_four_inverter.slx`, SHA-256
`3ca2e549c1606e2d371ce172c16f06c50f1d0f3ee690d6c7a8b004fee8cd3123`.
Saved with R2025a Update 1, 25.1.0.2973910. ZIP integrity and 42 XML documents parse.
The fault SLX and the three root fault/gain-tuning scripts are legacy; they are not
the new plant or training environment. See `model_inventory.json` for the full
block inventory and `static_model_review.json` for extracted controller programs.

DG1–DG4 each contain a 1000 V DC source, ideal-switch Universal Bridge, LCL-like
output network, phase-to-ground output measurements, abc/dq transformations,
P/Q calculation and filtering, primary droop, secondary command inputs and inner
voltage/current PI loops. The root connects four DGs through lines and loads.
`dw1..dw4` implement a ring consensus, with frequency pinning at DG1. Eight root
integrators integrate frequency and voltage-secondary derivatives. Their outputs
enter `DGn/dw` and `DGn/dE`, then gains of 5. Inner loops/PWM, line topology,
physical protection and existing limits are preserved in generated copies.

## Signal provenance (all paths relative to model root)

| Quantity | Exact path/port for DG i | Meaning and units |
|---|---|---|
| omega | `DGi/Sum2:1`, exported through `DGi/wi` / DG output 1 | Oscillator command, rad/s; NOT a PLL frequency measurement |
| Vd | `DGi/Demux:1`, exported as DG output 3 | Output-side dq d component, volts |
| Vq | `DGi/Demux:2` → existing `Goto3` | Output-side dq q component, volts; builder adds a read-only export |
| P | `DGi/From32:1` / DG output 2 | Filtered active power, W, local tag P |
| Q | `DGi/From33:1` / DG output 4 | Filtered reactive power, var, local tag Q |
| omega conventional | `DGi/Sum2:1` | `2*pi*60 - 1e-4*Pfiltered + 5*xi_omega` |
| Vd command conventional | `DGi/Sum6:1` | `338.8460811 - K1*Qfiltered + 5*xi_V` |
| source secondary gains | `DGi/Gain`, `DGi/Gain9` | Both 5 |
| omega states | `Integrator`, `Integrator1`, `Integrator2`, `Integrator3` | Raw integrated consensus states |
| voltage states | `Integrator4..Integrator7` | Raw integrated Q-consensus states |
| injected references | New sum immediately after `Sum2` and `Sum6` | rad/s and dq volts, before oscillator/inner loops |

Mapping code is `residual_rl/model_signal_map.m`. `verify_signal_map` checks ports,
transform normalization, P/Q tags, powergui rate, source gain values and sum signs
before editing a generated model. Unexpected topology stops with a saved MAT
mapping report. Compiled signal units, port dimensions and inherited rates remain
runtime checks. No PLL, RMS sensor, or manufacturer ratings were inferred.

## Voltage definition and the value near 344

`DGi/Output Side` measures phase-to-ground abc voltage (`Vo1` tag within each DG).
`From1` feeds `abc2dq0`, whose mask is `Power Variant`, q-axis leads d-axis,
90 degrees behind a-phase alignment. Its embedded `Constant2` matrix is
`(2/3)*[1 -1/2 -1/2; 0 sqrt(3)/2 -sqrt(3)/2; 1/2 1/2 1/2]`.
`Switch1` selects this matrix when mask index Power=1 because its threshold is 1
and its criterion is `u2 > Threshold`; the alternate sqrt(2/3) matrix is not selected.
Rotations preserve dq magnitude. Therefore, for balanced sinusoidal voltage,
`hypot(Vd,Vq)` equals phase-to-neutral peak amplitude. Vd alone equals it only if
Vq is approximately zero with the expected sign/alignment. It is not an RMS sensor.

`V_phase_peak = sqrt(2)*V_phase_rms`;
`V_LL_rms = sqrt(3)*V_phase_rms`;
`V_LL_peak = sqrt(2)*V_LL_rms`.
The stored 338.8460811 V reference corresponds to approximately 239.6 V phase RMS
and 415 V line-line RMS under those balanced conditions. If the reported 344 V
is that dq magnitude (or aligned Vd), the corresponding values are approximately
243.24 V phase RMS and 421.31 V line-line RMS. **There is no recorded 344 V trace in
this checkout, so its actual scope provenance and balance cannot be confirmed.**
The new observations use dq magnitude, not the unqualified Vd-only approximation.

`K_v_ref` does not occur in the original XML archive or the initial source files.
Its asserted value 0.5 cannot be traced from this repository. It is not retained
or assigned a meaning. It must be audited separately if present in a different
local model. `K1` DOES occur: the model InitFcn sets `K1=1e-4`, used at `Gain4`
as the primary Q–V droop coefficient in V/var; it is not `K_v_ref`.

## Power equations and timing

`Fcn4 = 1.5*(Vd*Iod + Vq*Ioq)`;
`Fcn5 = 1.5*(-Vd*Ioq + Vq*Iod)`.
These are filtered by `60/(s+60)` before the P/Q tags. The sign convention follows
the existing q-axis convention and must be checked with a known inductive-load
simulation locally before journal interpretation. The old voltage charts use
reactive disagreement only; voltage arguments are unused. Exact chart source is
preserved in the JSON audit. No explicit secondary integrator limits appear.

| Item | Stored value / treatment |
|---|---|
| nominal omega/f | 2*pi*60 rad/s / 60 Hz |
| root loads 1–4 | 100, 50, 10, 20 kW |
| switched Load 5 | 20 kW, 0 var, 415 V nominal LL RMS |
| Three-Phase Breaker1 | initially open; internal switching at 6 s |
| Pref/Qref blocks in each DG | steps at 10 s (10→15 kW; 54.1077→400 var), on the diagnostic reference/calculation branch |
| powergui | discrete, 0.2e-5 s (2 microseconds), 60 Hz |
| saved config sets | ode4, FixedStep auto, MaxStep 1e-4, StopTime 10 s |
| generated solver | ode4, explicit 2 microseconds; original comparison uses the same setting in memory |
| policy | 0.02 s (10,000 electrical steps per decision) |
| generated episode | 15 s; first 0.5 s residual startup gate |
| inner PI blocks | discrete, inherited sample time -1; compiled rates not yet known |

## Ambiguities and suspected defects

- Hardware P/Q ratings are absent. Four equal 50 kW/50 kvar study bases are
  explicitly assumptions (200 kW loaded study case / four), not recovered ratings.
  Confirm/replace them before full training; unequal bases are supported.
- Original voltage secondary has no direct nominal-voltage restoration and no
  explicit state saturation. Corrected mode adds restoration and limiting; original
  mode remains available for provenance and equivalence. These are different baselines.
- Inner decoupling gains contain `2*pi*50` despite a 60 Hz reference. They remain
  untouched: altering inner-loop tuning without runtime evidence would confound the study.
- `MGLib/Subsystem` is an external dq-to-abc library reference; runtime resolution is
  not established. Some inner PI saturation/anti-windup settings are inactive.
  Existing modulation saturation ±1 is retained; no new hardware safety is claimed.
- Oscillator command restoration is not independent measured grid-frequency
  restoration. Add verified PLL measurements for a stronger physical claim.
- The diagnostic Pref/Qref branch is distinct from the connected droop command
  branch; do not describe all stored step blocks as physical load events.
