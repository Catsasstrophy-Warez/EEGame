# Rev27 — Component-Authentic Construction & Maintenance

Rev27 promotes panel assembly from generic crimp/land/torque actions into component-aware construction truth.

## Added
- Terminal technologies: screw clamp, spring cage, Push-in, Push-X, stud/lug, pluggable, fused/knife disconnect, PE, shield clamp.
- Terminal definitions with conductor range, preparation acceptance, strip window, torque range, test-point and bridge-slot metadata.
- Tool truth: crimper die selection/condition, torque-tool setting/calibration error.
- Authentic terminations where component definition + preparation + tool condition determine findings and resistance.
- Educational SCCR groundwork: available fault current vs weakest modeled component rating. This is not a UL 508A certification engine.
- DVC maintenance state: relay replacement invalidates calibration/tracking until calibration and verification are completed.
- Burner field terminal map preserving separate pilot/low-fire/high-fire circuit returns plus ignition/flame/earth identities.

## Research-informed constraints
Phoenix Contact publishes multiple connection technologies with materially different conductor-preparation and torque behavior. Some Push-in/Push-X families accept flexible conductors with or without ferrules, while screw/stud products can have product-specific torque and strip requirements. Rev27 therefore rejects a universal 'every wire needs a ferrule and torque screwdriver' rule.

Fisher DVC6200 documentation describes travel calibration and relay adjustment/replacement workflows; Rev27 models the maintenance dependency without attempting to clone proprietary firmware.

Profire PF2100 documentation separates power, valve, thermocouple, ignition/flame-detection and expansion wiring. Rev27 preserves separate burner output circuit identities rather than collapsing them into one generic return.

## Validation
314/314 Swift Testing tests passed under Swift 6.2.1/Linux. Apple/Xcode/iOS/RealityKit validation remains separate.
