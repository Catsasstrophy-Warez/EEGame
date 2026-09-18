# Rev21 — Instrument Installation Physics & Burner Field Wiring

Rev21 promotes field instruments from logical objects into installation assemblies with diagnostic boundaries.

## Added
- PIT process tap, root valve, impulse leg, trapped pressure, leaks/freezing/plugging, hydrostatic head.
- 3-valve DP manifold with high/low blocks and equalizer.
- DP FIT square-root extraction, linear-misconfiguration behavior, low-flow cutoff.
- TIT thermowell lag, Type K/RTD identity, open/short/wrong-extension/poor-contact faults.
- LIT technology identity: hydrostatic DP, radar, GWR, displacer, ultrasonic; foam/false echo/reference/nozzle faults.
- DVC installation: loop controller, air supply, actuator pressure, packing friction, booster gain, stem and feedback separation.
- Burner field electrical train: 24 VDC supply, output fuse, pilot/main solenoid coils, ignition primary and open-coil faults.
- MX5 bus: node identities, two-end CAN termination audit, conductor open/short, RS-485 bias/termination health.
- Integrated Rev21FieldPackage.

## Research grounding
Vendor-specific behaviors are represented as educational abstractions. OEM manuals remain authoritative for actual equipment. Rev21 intentionally does not encode real-world work authorization, hazardous-location installation, LOTO, combustion commissioning, or certified BMS safety logic.

## Validation
244/244 Swift Testing tests pass with Swift 6.2.1 on Linux. Apple/Xcode/RealityKit/device validation remains outstanding.
