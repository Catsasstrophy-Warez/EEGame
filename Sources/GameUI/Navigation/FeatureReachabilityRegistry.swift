#if canImport(SwiftUI)
import Foundation

public enum EEProductionWorkspace75: String, CaseIterable, Identifiable, Sendable {
    case quickBench = "Quick Bench"
    case engineering = "Engineering"
    case field = "Field"
    public var id: String { rawValue }
}

public enum EEFeatureMaturity75: String, Sendable {
    case production
    case integrated
    case implemented
    case historical
}

public struct EEFeatureReachability75: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let workspace: EEProductionWorkspace75
    public let maturity: EEFeatureMaturity75
    public let accessibilityID: String
}

public enum EEFeatureReachabilityRegistry75 {
    public static let production: [EEFeatureReachability75] = [
        .init(id: "dmm", title: "Digital Multimeter", workspace: .quickBench, maturity: .production, accessibilityID: "quickBench.dmm"),
        .init(id: "scope", title: "4-Channel Scope", workspace: .quickBench, maturity: .production, accessibilityID: "quickBench.scope"),
        .init(id: "loop-cal", title: "Loop Calibrator", workspace: .quickBench, maturity: .production, accessibilityID: "quickBench.loopCalibrator"),
        .init(id: "analysis", title: "Analysis Lab", workspace: .engineering, maturity: .integrated, accessibilityID: "engineering.analysisLab"),
        .init(id: "golden-thread", title: "Golden Thread", workspace: .engineering, maturity: .integrated, accessibilityID: "engineering.goldenThread"),
        .init(id: "focus", title: "Universal Focus Object", workspace: .field, maturity: .integrated, accessibilityID: "field.focusObject"),
        .init(id: "vision", title: "Electrical Vision", workspace: .field, maturity: .production, accessibilityID: "field.electricalVision"),
        .init(id: "facility-power-88", title: "Rev88 Facility Power", workspace: .field, maturity: .integrated, accessibilityID: "field.rev88FacilityPower"),
        .init(id: "starter-bucket-88", title: "Rev88 Starter Bucket", workspace: .field, maturity: .integrated, accessibilityID: "rev88.starterBucket"),
        .init(id: "instrument-cluster-88", title: "Rev88 Unified Instruments", workspace: .field, maturity: .integrated, accessibilityID: "rev88.instrumentCluster"),
        .init(id: "causal-ribbon-88", title: "Rev88 Causal Ribbon", workspace: .field, maturity: .integrated, accessibilityID: "rev88.causalRibbon"),
        .init(id: "reality-scene", title: "RealityKit Scene (Scaffold)", workspace: .quickBench, maturity: .implemented, accessibilityID: "commandHeader.realityScene")
    ]
}
#endif
