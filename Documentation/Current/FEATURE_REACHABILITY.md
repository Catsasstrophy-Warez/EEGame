# Production Feature Reachability — Rev86 Audit

The current registry is implemented in `Sources/GameUI/Navigation/FeatureReachabilityRegistry.swift` and the current app root is `Rev72IntegratedLabView`.

| Feature | Workspace | Registry maturity | Accessibility ID |
|---|---|---|---|
| Digital Multimeter | Quick Bench | production | `quickBench.dmm` |
| 4-Channel Scope | Quick Bench | production | `quickBench.scope` |
| Loop Calibrator | Quick Bench | production | `quickBench.loopCalibrator` |
| Analysis Lab | Engineering | integrated | `engineering.analysisLab` |
| Golden Thread | Engineering | integrated | `engineering.goldenThread` |
| Universal Focus Object | Field | integrated | `field.focusObject` |
| Electrical Vision | Field | production | `field.electricalVision` |

Rev78–84 visual-system files remain implemented strata. They are not automatically promoted to production-certified reachability merely because the source exists. Xcode/XCUI verification should audit every button and navigation path before release certification.

## Removed: unreachable historical app-roots (post-Rev93)

25 GameUI files were deleted as dead code across two passes: each was a
former app root (`Rev31ProductionVisuals`/`Rev32LiveBoundGameView` through
`Rev55NumericalCredibilityView`, including the `Rev45`–`Rev55ProductionShell`
chain) superseded by a later revision's root, ending at today's
`Rev72IntegratedLabView`.

The first pass (15 files) used a single-hop "is this struct referenced by
anything" check, which is necessary but not sufficient: it missed that
`Rev31`/`Rev35`/`Rev38`/`Rev41` and the `Rev50`–`Rev55` chain were only
referenced by *each other*, not by anything reachable from the real root —
an entirely separate unreachable subtree, invisible to a single-hop check
because each file in it was "referenced by something," just not by
anything alive. This shipped a real regression (`Rev50PhysicalizedForensicsView`
called `Rev48Training`, deleted in the first pass) caught by
`macos-xcode` CI on the very next push — exactly the failure mode CI
exists to catch. The second pass used actual graph reachability (BFS from
`Rev72IntegratedLabView`, the same edges the app's own NavigationLinks use)
and found the remaining 10 files, verified with a corrected cross-reference
sweep before deletion. Full content of all 25 remains in git history.
