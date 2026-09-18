# Rev67 Integrated Technical Workbench

Rev67 deepens the I&E/Controls qualification stack with deterministic concurrent island solving, multi-rate simulation scheduling, physical instrument participation, transmitter service/trim separation, instruction-level PLC traces, and a fixed-storage forensic circular buffer.

## Architecture rules
- Simulation truth is never owned by SwiftUI.
- Concurrent independent solves publish in deterministic index order.
- Different physical domains may tick at different rates, but synchronize through explicit barriers/snapshots.
- Instruments participate in the measurement context rather than inventing values.
- Transmitter sensor trim, output trim, and range configuration are distinct service actions.
- Forensic storage is bounded and does not use `removeFirst()` on every full-buffer append.
- Natural-gas and coal process worlds remain separate.

## Next numerical work
Benchmark topology-cache restamping and island scheduling on large Golden Corpus networks before considering GPU sparse solves. Metal remains benchmark-driven, not assumed.
