# Rev46 Playable Integration

Rev46 is an integration-first revision. It does not merge the natural-gas and coal/mining physical worlds.

## Production changes
- Rev46ProductionShell is now the app root.
- Natural Gas Forensics exposes Rev40 compressor/header/VFD/motor/rod-load truth.
- Coal & Mining Operations exposes Rev44 belt/atmosphere/longwall/preparation/train truth.
- Universal Golden Thread builds a searchable cross-surface identity graph from the existing gas and coal registries while retaining world identity.
- Forensic Timeline stores independent world-specific snapshots and supports nearest-time reconstruction without crossing industrial boundaries.
- Universal instrument sessions record selected timeline channels as evidence with simulation-truth provenance.
- Electronics Bench and Training & Instruments are linked from the production shell.

## Validation
Swift 6.2.1/Linux: 567/567 tests passed in 14 suites.
Apple UI/device validation remains outstanding and must be performed in Xcode.
