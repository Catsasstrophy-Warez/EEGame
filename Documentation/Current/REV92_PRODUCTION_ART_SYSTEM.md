# Rev92 Production Art System

Rev92 adds the next production-art layer: authored equipment faceplates/tags, wire-number identities, inspectable electrical-room composition, equipment age/condition variants, environmental operating-state presentation, and a true UI binding from the Facility page to `facility88.scope.samples`.

## Important truth improvement
The dedicated Rev92 transient scope is now fed the ScenarioEngine `EETransientRing87` samples produced by `EEFacilityPowerMachine88` (`L1.V`, etc.), rather than relying on the presentation-only seed waveform. The Rev91 generic preview fallback remains available only when no physical samples are supplied.

## Visual boundaries
The new room/equipment art is procedural SwiftUI/RealityKit composition. It is a major fidelity scaffold, not a claim of OEM-exact CAD geometry, photogrammetry, or finished AAA asset production. Audio is represented as state/UI in this source-only pass; no copyrighted or external sound assets are bundled.
