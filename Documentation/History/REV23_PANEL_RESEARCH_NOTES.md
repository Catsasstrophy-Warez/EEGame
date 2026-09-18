# Rev23 Panel Research & Layout Synthesis

## Typical compressor-station panel families
1. Station/Unit Control Panel: HMI, PLC/RTU, remote I/O/MX5, 24 VDC supply/UPS, Ethernet/CAN/RS-485, relays, analog conditioning/IS barriers, field terminals, ground/shield bars.
2. MCC/Drive: incoming disconnect/protection, horizontal/vertical wireways, starters/overloads or VFDs, control power, motor feeders.
3. Burner Management Panel: disconnect/power, BMS controller, ignition interface/coil, pilot/main relays/outputs, ESD/POC/pressure/level/TC field terminals, grounding.
4. Marshalling/IS Panel: field terminal strips, fused/disconnect/test terminals, IS barriers, isolators/repeaters/solenoid drivers, system-side terminals and shield/ground bars.
5. Junction/Remote I/O Panel: environmental enclosure, field terminal strips, remote I/O/MX5, network termination, surge protection, DC distribution.

## Layout synthesis used in Rev23
- Keep power/drive heat and noise physically distinct from analog/IS/network zones.
- Put field termination in accessible lower/side zones with wire duct paths.
- PLC/I/O and networking form a control zone; analog/IS marshalling forms a sensitive-signal zone.
- BMS has a dedicated safety/control zone and separate field terminations.
- MCC representation includes explicit horizontal/vertical wireway concepts from industrial MCC practice.
- Panel heat is an engineering state, not decoration.
- Every device, terminal, wire, cable core, I/O channel, controller tag and HMI tag should ultimately share stable identities and drawing cross-references.

## Important scope rule
These are game/simulation engineering templates. Hazardous-location classification, SCCR, arc-flash, conductor sizing, enclosure rating, segregation, intrinsic-safety entity parameters, functional-safety/SIL design, burner safeguards and NEC/NFPA/UL/CSA requirements must be represented from current authoritative requirements and project/OEM documentation before any layout is treated as a real installation design.
