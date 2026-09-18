# Electric Engineer Game — Rev88 Facility Power & Visual Fidelity Baseline

A deterministic, physics-first industrial electrical / instrumentation / controls / automation simulator-game.

**North star:** See it → wire it → energize it → measure it → break it → diagnose it → understand why it failed.

## Current authoritative baseline
Rev87 is the current causal-depth baseline. It extends the Rev85 Continuous Causal Machine without introducing a parallel simulation truth.

Rev86 currently includes:
- breaker/fuse time-current curve infrastructure with breaker thermal memory and magnetic pickup,
- temperature-dependent contact resistance, heating and degradation,
- contactor coil/armature pull-in, dropout and bounce behavior,
- three-phase motor starting, slip, inrush, torque, heating and feeder sag,
- PLC discrete-input threshold/hysteresis/filtering,
- CircuitMNA-backed 4–20 mA input burden/compliance behavior,
- DMM/LoZ measurement loading,
- real simulation-channel scope buffers,
- state-derived SOE transitions and first-divergence reconstruction,
- Codable persistence for the new causal states.

## Truth architecture
The production rule remains simple: **UI does not own physical truth.**

Authoritative causal flow:

`CircuitMNA → protection/thermal → contacts/contactors/motors → PLC I/O → process → instrumentation → evidence/SOE/UI`

Measurements, scopes, event timelines and forensic views must observe shared simulation state rather than synthesize convenient diagnostic answers.

## Project map
- `Sources/CircuitMNA/` — circuit solution and sparse/MNA infrastructure
- `Sources/ElectricalCore/` — shared electrical primitives
- `Sources/ScenarioEngine/` — facility, simulation, controls, instrumentation, evidence and training logic
- `Sources/GameUI/` — production SwiftUI surfaces
- `Sources/ElectricEngineerApp/` — app entry point
- `Tests/` — portable and causal-depth test suites
- `Scripts/` — validation and Xcode-readiness tooling
- `Documentation/Current/` — current architecture, truth, test and Rev86 documentation
- `Documentation/History/` — superseded revision reports retained for provenance
- `Documentation/VisualReferences/` — design references and mockups, never runtime evidence
- `Documentation/Manifests/` — generated cross-computer package inventories

## Validation status
Observed before this organization pass:
- `python3 Scripts/validate_causal_depth86.py`: **12/12 PASS**
- portable `ScenarioEngine` build had previously been reported as passing in the Rev86 handoff; this package is revalidated after cleanup before release.

Apple SDK, signing, simulator and physical-device claims require macOS/Xcode and are never inferred from portable Swift validation.

## Start here
- [Rev86 causal-depth report](Documentation/Current/REV86_CAUSAL_DEPTH_REPORT.md)
- [Architecture](Documentation/Current/ARCHITECTURE.md)
- [Simulation truth](Documentation/Current/SIMULATION_TRUTH.md)
- [Feature matrix](Documentation/Current/FEATURE_MATRIX.md)
- [Feature reachability](Documentation/Current/FEATURE_REACHABILITY.md)
- [Test matrix](Documentation/Current/TEST_MATRIX.md)
- [UI navigation](Documentation/Current/UI_NAVIGATION.md)
- [Release status](Documentation/Current/RELEASE_STATUS.md)
- [Rev87 source-domain migration map](Documentation/Current/SOURCE_DOMAIN_MAP_REV86.md)
- [Visual references](Documentation/VisualReferences/README.md)

## Next depth target
Rev87 should converge the existing components into the authoritative facility topology: per-phase MNA feeders, transformer/source equivalents, phase loss/unbalance, overload classes, contact erosion/welding, calibrated motor equivalent circuits, ground-fault paths, native analog-loop topology, ADC error/quantization and deterministic replay hashes.


## Rev88 Facility Power & Visual Fidelity
Rev88 deepens the Rev87 causal machine with complex three-phase phasors, transformer sequence impedances, grounding/fault analysis, conductor thermal state, negative-sequence motor heating, control-power sag, and a shared facility measurement frame. GameUI adds a reachable Facility Power dashboard, MCC lineup, power-flow visualization, fault selector, and thermal truth surface. All diagnostic views are intended to converge on the same physical solved state.


## Rev89 Spatial Equipment & Visual Fidelity
Rev89 extends the Rev88 facility-power baseline with spatial MCC internals, PLC/I/O rack, terminal strip, motor cutaway, and shared-truth diagnostic vision modes. See `Documentation/Current/REV89_SPATIAL_VISUAL_FIDELITY.md`.


## Rev90 Physical Interaction & Production Visuals
Rev90 adds animated cabinet access, conductor routing, probe placement, scope visualization, protection cutaways and thermal wear surfaces on the shared facility-power truth. See `Documentation/Current/REV90_PHYSICAL_INTERACTION_VISUALS.md`.


## Rev91 Immersive Production Visuals
RealityKit MCC volume, terminal harnesses, interactive lead placement, buffered scope display, animated process machinery and facility environment surfaces. See `Documentation/Current/REV91_IMMERSIVE_PRODUCTION_VISUALS.md`.


## Rev92 Production Art System
Adds equipment faceplates/tags, wire-number identities, facility-room composition, aging/condition states, environment presentation, and a physical ScenarioEngine transient-ring binding for the Rev92 scope. See `Documentation/Current/REV92_PRODUCTION_ART_SYSTEM.md`.


## Rev93 Causal Interaction
Adds CircuitMNA-loaded DMM modes, canonical conductor/node identities and mechanically animated contactor presentation. See `Documentation/Current/REV93_CAUSAL_INTERACTION.md`.
