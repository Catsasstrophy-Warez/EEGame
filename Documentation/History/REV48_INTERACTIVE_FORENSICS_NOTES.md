# Rev48 Interactive Forensics

Rev48 is an integration release focused on playable engineering workflow rather than new industrial process breadth.

## Major additions
- Electronics Bench 2.0: placeable components, explicit terminals, point-to-point conductors, continuity graph, conductor removal.
- Training Qualifications: eight-stage progression (observe, demonstrate, build, measure, commission, diagnose, repair, prove) for all eleven schools.
- Interactive Instrument Placement: instrument-specific placement rules; invalid placement cannot create evidence.
- Navigable Industrial Worlds: explicit world-scoped facility connections and travel times for Natural Gas and Coal & Mining.
- Diagnostic Planner: proposes discriminating tests based on the Evidence Board rather than proposing answers.
- Evidence provenance remains simulation-truth only.
- Golden Thread continues to bind physical assets to engineering references while preserving world ownership.

## Separation rule
Natural Gas and Coal & Mining remain independent physical/process worlds. Shared diagnostic, electrical, instrument, evidence and UI infrastructure does not merge facility truth.

## Validation
Swift 6.2.1/Linux: 588/588 tests passed in 16 suites. Apple/Xcode/device validation is still outstanding.
