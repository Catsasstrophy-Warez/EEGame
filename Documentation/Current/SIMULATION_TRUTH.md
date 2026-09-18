# Simulation Truth — Rev86

## Non-negotiable rule
Measurements must originate from simulated state or a modeled instrument interaction. UI text, artwork and tutorial copy are presentation, not authority.

## Physical truth
Circuit topology, source/load state, protection memory, conductor/contact state, contactor dynamics, motor dynamics, PLC input electronics and analog-loop burden/compliance must evolve from the same causal machine.

## Measurement truth
A DMM, LoZ meter, scope, calibrator or PLC input is an electrical participant/observer with modeled loading, thresholds, timing and limits. Diagnostic instruments must not reveal values that the underlying model cannot support.

## Evidence truth
SOE records transitions derived from state changes. Scope history records actual simulation channels. First-divergence analysis compares observed histories. Evidence records provenance and must not invent missing measurements.

## Repair truth
Work-order completion cannot directly overwrite physical truth. A repair changes equipment state; recommissioning and proof-of-repair establish closure.

## Missing/invalid states
Floating, unavailable, invalid or unresolved measurements should remain explicit rather than being replaced with convenient values.
