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

15 GameUI files were deleted as dead code: each was a former app root
(`Rev32LiveBoundGameView` through `Rev71CompetitiveUXAssimilationView`,
including the `Rev45`–`Rev49ProductionShell` chain) superseded by a later
revision's root, ending at today's `Rev72IntegratedLabView`. None were
reachable from the app and none were referenced by any surviving file, test,
or the App target — confirmed by a full cross-reference sweep before
deletion, not just an absence from the registry above. Full content is
preserved in git history on this branch prior to that commit.
