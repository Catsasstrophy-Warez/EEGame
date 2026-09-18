# Rev30 Equipment Digital Twin Notes

Rev30 turns the Rev29 equipment registry into persistent installed equipment instances. Each twin retains installation location, configuration, lifecycle state, event history, calibration records, maintenance records, commissioning evidence, operating hours, and latent workmanship defects.

The new HART-style workspace is equipment-dependent. Pressure-transmitter twins expose PV/range/damping/current concepts; DVC-style twins expose analog input, travel, supply pressure, and calibration-required state. These are educational abstractions grounded in public OEM concepts, not replicas of proprietary firmware or service menus.

GoldenToolSession binds physical measurements to the same Golden Thread identity used by cabinet, loop, wiring, terminal, I/O, PLC and HMI views. CommissioningDossier projects persistent twin evidence into a handoff/return-to-service record.
