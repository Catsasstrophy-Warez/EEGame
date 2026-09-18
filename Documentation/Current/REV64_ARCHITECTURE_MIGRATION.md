# Rev64 Architecture Migration Plan

The external architecture review correctly identified revision-prefixed production files as accumulating debt. Rev64 does not mass-rename public source because that would combine a behavioral release with a high-risk structural migration.

Migration sequence:
1. Introduce stable semantic modules/names beside revision implementations.
2. Add compatibility aliases/adapters and architecture tests.
3. Move data-only scenarios into Codable catalogs.
4. Move UI to observation/view-model boundaries.
5. Profile sparse solver allocation before replacing storage.
6. Benchmark CPU sparse solve before considering Metal. GPU offload is not assumed to be faster for small/irregular sparse islands.
7. Retire RevXX implementations only after regression equivalence.

Target stable domains: SimulationCore, ElectricalSimulation, Electronics, Instrumentation, Controls, IndustrialNetworks, Diagnostics, Evidence, GoldenThread, Commissioning, Training, Career, NaturalGasWorld, CoalMiningWorld, GameUI.
