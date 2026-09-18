# Rev93 Causal Interaction

Rev93 starts converting visual interaction into electrical interaction.

- DMM high-Z and LoZ modes are represented as different input impedances and solved through CircuitMNA.
- Meter UI exposes its input resistance and loading current.
- Canonical conductor identities map MCC bus, protection, contactor, motor, control transformer, terminal block and PLC analog nodes.
- Contactor presentation now has continuous spring/armature travel animation driven by the physical conducting state.
- Existing Rev92 scope remains bound to the ScenarioEngine transient ring.

Current boundary: the Rev93 meter-loading circuit is a focused CircuitMNA instrument subnetwork. Full insertion of arbitrary probes into the complete three-phase facility topology is the next solver integration step. Canonical harness identities are intentionally the bridge for that work.
