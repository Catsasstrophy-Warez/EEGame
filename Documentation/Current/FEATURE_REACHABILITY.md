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

Rev78–84 visual-system files and older Rev31–72 views remain implemented strata. They are not automatically promoted to production-certified reachability merely because the source exists. Xcode/XCUI verification should audit every button and navigation path before release certification.
