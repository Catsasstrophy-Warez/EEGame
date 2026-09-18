#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct ElectricalWorkbenchView: View {
    @State private var selected: BenchTerminal = .supply
    public init() {}
    public var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("BENCH 01 · 24 VDC STARTER").font(.headline)
                Text("Physical panel ↔ schematic identity foundation").font(.subheadline).foregroundStyle(.secondary)
                HStack { ForEach(BenchTerminal.allCases,id:\.rawValue){t in Button(t.rawValue){selected=t}.buttonStyle(.bordered)} }.frame(maxWidth:.infinity)
                GroupBox("Selected terminal") { Text("\(selected.rawValue) · node \(BenchLayout.node(for:selected))").monospacedDigit().frame(maxWidth:.infinity,alignment:.leading) }
                GroupBox("Next interaction layer") { Text("Drag red/black DMM probes onto these terminal identities; measurements will come from the ElectricalSnapshot, never UI-authored values.").frame(maxWidth:.infinity,alignment:.leading) }
                Spacer()
            }.padding().navigationTitle("Electrical Engineer")
        }
    }
}
#endif
