# Feature Matrix — Rev86

| Domain | Current implementation | Primary truth/source |
|---|---|---|
| Circuit solution | Sparse/MNA electrical foundation | `CircuitMNA` |
| Breaker/fuse behavior | TCC interpolation, breaker thermal memory, magnetic pickup | `ScenarioEngine/Simulation/CausalDepth86.swift` |
| Contacts/contactors | Temperature-dependent resistance, heating/degradation, RL coil, armature, touch/bounce/weld foundation | Rev86 causal depth |
| Three-phase motor | Starting approximation, slip, inrush, torque, inertia, load, heat, feeder sag | Rev86 causal depth |
| PLC discrete input | Threshold, hysteresis, filtering | Rev86 causal depth |
| 4–20 mA loop | MNA-backed AI burden and transmitter compliance limitation | Rev86 + CircuitMNA |
| DMM/LoZ | Input-loading model including ghost-voltage experiments | Rev86 causal depth |
| Scope | Real simulation-channel ring buffer | Rev86 causal depth |
| SOE / first divergence | State-derived transitions and observed-history comparison | Rev86 evidence path |
| Natural Gas world | Separate process world | ScenarioEngine world/domain layers |
| Coal/Mining world | Separate process world | ScenarioEngine world/domain layers |
| Training | Deep competency/qualification strata retained | ScenarioEngine Rev56–72 |
| Production UI | Rev72 integrated lab root plus reachable Rev75 production registry and Rev78–84 visual systems | `GameUI` |
| Persistence | Codable causal states plus prior persistence systems | ScenarioEngine |
