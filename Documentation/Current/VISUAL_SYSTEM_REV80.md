# Rev80 Facility Causal Twin

Rev80 expands the interactive workbench into a facility-scale causal navigator.

Implemented:
- station/building/MCC/section/bucket/PLC/terminal/cable/JB/instrument/actuator/process hierarchy;
- persistent facility object identities and breadcrumb traversal;
- causal Golden Thread with expected vs observed state;
- first-divergence calculation and visual boundary highlighting;
- cross-domain control → mechanical → instrumentation → process chain;
- live process-skid representation;
- fault-dependent divergence movement;
- tests for healthy, open-circuit, high-resistance, breadcrumb and identity behavior.

The diagnostic principle is not to reveal the root cause. The system identifies the first measured disagreement between expected and observed states and directs attention to that boundary. The player still chooses and performs the discriminating test.

RealityKit remains the next presentation layer after Apple-device verification of these identity and causal contracts.
