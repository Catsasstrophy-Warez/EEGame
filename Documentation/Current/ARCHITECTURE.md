# Architecture — Rev86

## Production boundaries
- **ElectricalCore** defines shared electrical primitives and base truth types.
- **CircuitMNA** owns circuit solution infrastructure, sparse execution, nodal/MNA behavior and numerical electrical truth.
- **ScenarioEngine** owns industrial simulation, causal propagation, controls, instrumentation, process worlds, diagnostics, training, persistence and evidence.
- **GameUI** observes and manipulates ScenarioEngine truth through production SwiftUI surfaces. It must not manufacture physical measurements or forensic conclusions.
- **ElectricEngineerApp** is the app entry point.

## Current app root
`Sources/GameUI/App/ElectricEngineerGameView.swift` currently enters `Rev72IntegratedLabView`. The production reachability registry remains `EEFeatureReachabilityRegistry75`; revision numbers here are migration strata, not separate truths.

## Causal rule
Authoritative physical/diagnostic direction:

`CircuitMNA → protection/thermal → contacts/contactors/motors → PLC I/O → process → instrumentation → evidence/SOE → GameUI`

UI state may select, display and command the simulation. It may not replace the simulation as the source of voltage, current, waveform, equipment status or root-cause evidence.

## World isolation
Natural Gas and Coal/Mining share generic engineering foundations but retain separate process truth, time, equipment state and forensic histories.

## Revision strata
Many files retain `RevXX` names to preserve regression safety and historical API compatibility. Do not bulk rename these files. Migrate active behavior behind capability-oriented facades and domain folders incrementally. See `SOURCE_DOMAIN_MAP_REV86.md`.

## Rev87 architecture target
Rev87 should deepen the same truth path with per-phase feeder topology, transformer/source equivalents, phase loss/unbalance, overload classes, contact erosion/welding, calibrated motor equivalent circuits, ground-fault paths, native MNA 4–20 mA loops, ADC error/quantization and deterministic replay hashes.
