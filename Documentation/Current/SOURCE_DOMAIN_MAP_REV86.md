# Source Domain Map — Rev86

This map is an organization bridge between revision-numbered implementation strata and the capability-oriented Rev87 architecture. It intentionally avoids destructive bulk renames.

## Stable modules
- `Sources/ElectricalCore` — shared electrical primitives.
- `Sources/CircuitMNA` — numerical circuit solution / MNA / sparse execution.
- `Sources/ScenarioEngine` — simulation and industrial domains.
- `Sources/GameUI` — SwiftUI presentation and interaction.
- `Sources/ElectricEngineerApp` — app entry.

## ScenarioEngine capability destinations
Future active code should converge toward these domains while legacy RevXX APIs remain available until callers/tests migrate:

| Capability | Existing examples | Rev87 destination |
|---|---|---|
| Electrical network | `Rev6PowerAndInstrumentation`, `Rev13CausalPlant`, `Simulation/UnifiedElectricalTruth84` | `ElectricalNetwork/` |
| Protection / thermal | `Simulation/CausalDepth86` | `Protection/` |
| Motors / contactors / drives | `PhysicalStarter`, `Rev5IntegratedStarter`, `Rev7AutomationDrive`, Rev86 causal depth | `Machines/` |
| PLC / controls / protocols | `Controls/`, `Rev8PanelAutomation`, `Rev66DeepPhysicalControls` | `Controls/` |
| Instrumentation / loops | `Instrumentation/`, `Rev20…`, `Rev21…`, `Rev64…` | `Instrumentation/` |
| Evidence / SOE / forensics | `Evidence/`, `Rev40…`, `Rev48…`, `Rev68…`, Rev86 scope/SOE | `Evidence/` |
| Process worlds | `Rev37…`, `Rev41…`, `Rev42…`, world-specific strata | `Worlds/NaturalGas/`, `Worlds/CoalMining/` |
| Training / qualification | `Rev56…` through `Rev72…` | `Training/` |
| Persistence / replay | Rev36 persistent shift + later snapshot/replay layers | `Persistence/` / `Replay/` |

## Migration rules
1. Do not move a legacy symbol until references and tests are mapped.
2. Prefer new capability-oriented files over new revision-numbered top-level files.
3. Keep one physical truth. A facade may reorganize APIs but must not duplicate state.
4. Add tests before and after migrations.
5. Regenerate Xcode project membership after structural changes.
