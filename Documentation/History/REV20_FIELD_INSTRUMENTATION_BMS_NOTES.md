# Rev20 Field Instrumentation & Burner Management Notes

Rev20 expands the simulation vocabulary around field instrumentation and combustion controls. Models are educational abstractions and must not be used as certified burner-management, SIS, hazardous-location, or field-work procedures.

## Added executable families
- TIT/PIT/FIT/LIT indicating transmitter loops with LRV/URV, damping, drift, loop supply/burden, open loop, alarm current, plugged/frozen process sensing.
- Flow-meter abstraction supporting differential-pressure, magnetic, Coriolis, vortex, and turbine identities.
- I/P electro-pneumatic conversion with supply-air and failure modes.
- DVC-style digital valve controller with 4–20 mA command, pneumatic supply, valve travel, friction/stiction-style behavior, travel deviation, HART-health placeholder, and diagnostic alerting.
- Murphy Interchange MX5-style modular I/O abstraction with channel types, CAN-node identity, forced values, duplicate-node and CAN-termination auditing. Exact deployed board option and channel population must remain configuration-driven.
- Burner-management state machine with start request, permissive precheck, proof-of-closure, ignition, pilot flame proving, main trial, running, safe shutdown, lockout, ESD/high-temperature/high-pressure/low-pressure/low-level/flame trips, reset gating, and event history.
- Integrated burner train connecting TIT/PIT/LIT/FIT, valve control, MX5 I/O, and BMS.

## Next fidelity work
1. Thermocouple millivolt physics, cold-junction compensation, open-TC upscale/downscale behavior.
2. RTD 2/3/4-wire lead resistance and transmitter conversion.
3. PIT manifolds, equalize/block valves, wet/dry legs, impulse-line leaks/plugs/freezing.
4. DP flow square-root extraction, density compensation, primary elements, totalization.
5. LIT technologies: DP, radar, guided-wave radar, displacer; dielectric/foam/false-echo effects.
6. DVC positioner pneumatics: I/P stage, relay/booster, actuator chamber pressure, stem friction, packing, deadband, travel calibration and signature tests.
7. I/P calibration, nozzle/flapper contamination, supply regulator/filter and downstream leakage.
8. BMS flame-sensing physics: thermocouple and ionization/flame-rod channels, ignition transformer/coil, pilot/main solenoids, proof-of-closure and valve feedback.
9. PF2100/PF2150-inspired configurable terminal/card architecture, 4–20 mA expansion, RS-485/Modbus, event/shutdown code model, without copying proprietary firmware.
10. MX5 option-board catalog driven by actual panel drawings/manuals once exact board variants are known.
11. Electrical panel hardware: 12/24 VDC supply, fuses, relays, terminal blocks, surge protection, grounding, barriers/isolators, shield/drain wiring, RS-485/CAN termination and power-quality faults.
12. Golden Thread paths from process condition through sensing, transmitter, cable, barrier, MX5/PLC/BMS, final element, combustion/process response, HMI, historian and SOE.
