# Current Architecture

Production dependency direction:

`ElectricalCore → CircuitMNA → ScenarioEngine → GameUI → ElectricEngineerGame`

Rev75 adds a production orchestration boundary:

`UI command → EESimulationCoordinator75 → physical/electrical truth → snapshot → measurement/evidence → UI`

Historical revision-numbered implementations remain temporarily compiled while migration to semantic directories proceeds. New production APIs should use semantic directories rather than creating new revision-numbered architecture files.
