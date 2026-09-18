#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct ElectricEngineerGameView: View {
    public init() {}

    public var body: some View {
        Rev72IntegratedLabView()
            .accessibilityIdentifier("app.root")
    }
}
#endif
